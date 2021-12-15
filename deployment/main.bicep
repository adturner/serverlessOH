// az login
// az bicep build --file main.bicep --outfile main.json
// az deployment group create --resource-group HackerThreeRG --template-file main.bicep --what-if

@description('Tags to be applied to resources that are deployed in this template')
param resourceTags object  = {
  environmentName: 'Azure Serverless OpenHack'
  challengeTitle: 'Challenge 3 Ice Cream Ratings Deploy Infrastructure'
  expirationDate: '12/21/2021'
}

@description('Deployment Prefix - all resources names created by this template will start with this prefix')
@minLength(3)
@maxLength(7)
param deploymentPrefix string

//@description('FHIR Server Azure AD Tenant ID (GUID)')
//param fhirServerTenantName string = subscription().tenantId

var tenantId = subscription().tenantId
var resourceLocation = resourceGroup().location

// Unique Id used to generate resource names
var uniqueId  = take(uniqueString(subscription().id, resourceGroup().id, deploymentPrefix),6)
// Default resource names

// Azure key Vault
var kvName   = '${deploymentPrefix}${uniqueId}kv'

// Log Analytics Workspace
var laName   = '${deploymentPrefix}${uniqueId}laws'
// Functions storage account
var storageAccountName   = '${deploymentPrefix}${uniqueId}funstg'
// App Service Plan Name
var appServicePlanName = '${deploymentPrefix}${uniqueId}apppln'
// ratings function app name
var functionAppName = '${deploymentPrefix}${uniqueId}ratings'
// ratings app insights name
var ratingsAppInsightName = '${deploymentPrefix}${uniqueId}ratingsai'
var ratingsDatabaseName = '${deploymentPrefix}${uniqueId}ratingsdb'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: laName
  location: resourceLocation
  tags: resourceTags
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}
resource logAnalyticsWorkspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = {
  scope: logAnalyticsWorkspace
  name: 'diagnosticSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' =  {
  name: kvName
  location: resourceLocation
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    softDeleteRetentionInDays: 7
    enableSoftDelete: true
    enableRbacAuthorization: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}
// enable diagnostic settings for KV
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: keyVault
  name: 'defaultSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 7
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy:{
          enabled: true
          days: 7
        }
      }
    ]
  }
}
resource functionsStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: resourceLocation
  tags: resourceTags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    isHnsEnabled: false
    isNfsV3Enabled: false
    minimumTlsVersion: 'TLS1_2'
  }
}
resource functionsBlobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: '${functionsStorageAccount.name}/default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
resource functionsFileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = {
  name: '${functionsStorageAccount.name}/default'
  properties: {
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}
resource functionsQueueServices 'Microsoft.Storage/storageAccounts/queueServices@2021-06-01' = {
  name: '${functionsStorageAccount.name}/default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}
resource functionsTableServices 'Microsoft.Storage/storageAccounts/tableServices@2021-06-01' = {
  name: '${functionsStorageAccount.name}/default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}
resource storageAcountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: functionsStorageAccount
  name: 'defaultSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy:{
          enabled: true
          days: 7
        }
      }
    ]
  }
}
resource appServicePlan 'Microsoft.Web/serverfarms@2020-09-01' = {
  name: appServicePlanName
  location: resourceLocation
  tags: resourceTags
  sku: {
    name: 'S1'
  }
  kind: 'functionapp'
}
resource appServicePlanDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: appServicePlan
  name: 'defaultSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [ 
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy:{
          enabled: true
          days: 7
        }
      }
    ]
  }
}
resource ratingsFunctionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: functionAppName
  location: resourceLocation
  tags: resourceTags
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'functionapp'
  properties: {
    enabled: true
    httpsOnly: true
    clientAffinityEnabled: false
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
      ftpsState:'FtpsOnly'
      minTlsVersion: '1.2'
    }
  }
}
resource ratingsFunctionAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: ratingsFunctionApp
  name: 'defaultSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [ 
      {
        category: 'FunctionAppLogs'
        enabled: true
        retentionPolicy:{
          enabled: true
          days: 7
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy:{
          enabled: true
          days: 7
        }
      }
    ]
  }
}
resource ratingsAppInsights 'microsoft.insights/components@2020-02-02-preview' = {
  name: ratingsAppInsightName
  location: resourceLocation
  kind: 'web'
  tags: resourceTags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}
resource ratingsDatabase 'Microsoft.DocumentDB/databaseAccounts@2021-07-01-preview' = {
  name: ratingsDatabaseName
  location: resourceLocation
  tags: resourceTags
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    createMode: 'Default'
    locations:[
      {
        locationName: resourceLocation
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Eventual'
    }
    databaseAccountOfferType: 'Standard'
  }
}
resource ratingsDatabaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: ratingsDatabase
  name: 'defaultSettings'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [ 
      {
        category: 'DataPlaneRequests'
        enabled: true
        retentionPolicy:{
          enabled: true
          days: 7
        }
      }
      {
        category: 'TableApiRequests'
        enabled: true
        retentionPolicy:{
          enabled: true
          days: 7
        }
      }
    ]
    metrics: [
      {
        category: 'Requests'
        enabled: true
        retentionPolicy:{
          enabled: true
          days: 7
        }
      }
    ]
  }
}
// function app settings
var keyVaultUri = keyVault.properties.vaultUri 

resource ratingsAppSettings 'Microsoft.Web/sites/config@2021-02-01' = {
  name: 'appsettings'
  parent: ratingsFunctionApp
  properties: {
    'FUNCTIONS_EXTENSION_VERSION': '~3'
    'FUNCTIONS_WORKER_RUNTIME': 'dotnet'
    'APPINSIGHTS_INSTRUMENTATIONKEY': ratingsAppInsights.properties.InstrumentationKey
    'AzureWebJobsStorage': 'DefaultEndpointsProtocol=https;AccountName=${functionsStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionsStorageAccount.id, functionsStorageAccount.apiVersion).keys[0].value}'
    'AzureWebJobs.ImportBundleBlobTrigger.Disabled': '1'
  }
}
// FHIR Bulk Loader Code Repo
var ratingsRepoUrl = 'https://github.com/adturner/serverlessOH'
var ratingsRepoBranch = 'main'
//deploy fhir loader code
resource ratingAPIUsingCD 'Microsoft.Web/sites/sourcecontrols@2020-12-01' = {
  dependsOn: [
    ratingsAppSettings
  ]
  name:'web'
  parent: ratingsFunctionApp
  properties: {
    repoUrl: ratingsRepoUrl
    branch: ratingsRepoBranch
    isManualIntegration: true
  }
}
