@description('Tags to be applied to resources that are deployed in this template')
param resourceTags object  = {
  environmentName: 'Serverless OpenHack - Create Storage Account'
}
@description('Storage Account Name')
param storageAccountName string

// create export storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: resourceGroup().location
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
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: '${storageAccount.name}/default'
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
