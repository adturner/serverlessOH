// Default URL for triggering event grid function in the local environment.
// http://localhost:7071/runtime/webhooks/EventGrid?functionName={functionname}
using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Azure.EventGrid.Models;
using Microsoft.Azure.WebJobs.Extensions.EventGrid;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.WebJobs.Extensions.DurableTask;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.IO;
using System.Net.Http;
using System.Text.Encodings;

namespace RatingsAPI
{
    public static class BatchDurableFunction
    {
        [FunctionName("BatchDurableFunction")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            //[EventGridTrigger]EventGridEvent eventGridEvent,
            [DurableClient] IDurableEntityClient client,
            ILogger log)
        {

            string output = "{\"api\": \"PutBlob\",\"clientRequestId\": \"5c76a254 - ed82 - 4b5b - 930b - 80c1355b7098\",\"requestId\": \"1560a72e - 201e-0060 - 2d9a - f29b43000000\",\"eTag\": \"0x8D9C0B1C130CC34\",\"contentType\": \"application / octet - stream\",\"contentLength\": 925,\"blobType\": \"BlockBlob\",\"url\": \"https://ohserverless98765.blob.core.windows.net/batch-files/20211216160800-ProductInformation.csv\",\"sequencer\": \"00000000000000000000000000008B8000000000005fe163\",\"storageDiagnostics\": {\"batchId\": \"2691a457-2006-0006-009a-f22919000000\"}}";
            JObject jsonResult = JObject.Parse(output);
            string fileName = jsonResult.SelectToken("url").ToString();

            fileName = fileName.Split('/')[fileName.Split('/').Length - 1];
            fileName = fileName.Split('-')[0];



            //read current state 
            
            var entityId = new EntityId("Counter", fileName);
            var response = await client.ReadEntityStateAsync<Counter>(entityId);

            if (response.EntityExists)
            {
                if (response.EntityState.Value >= 2)
                {
                    var theResponse = combineFiles(fileName);
                }
                else
                {
                    await client.SignalEntityAsync(entityId, "Add", 1);
                }
            }
            else
                await client.SignalEntityAsync(entityId, "Add", 1);
            
            return new OkObjectResult(response);
            
        }

        private async static Task<HttpResponseMessage> combineFiles(string entityName)
        {
            string file1 = string.Format("https://ohserverless98765.blob.core.windows.net/batch-files/{0}-OrderHeaderDetails.csv", entityName);
            string file2 = string.Format("https://ohserverless98765.blob.core.windows.net/batch-files/{0}-OrderLineItems.csv", entityName);
            string file3 = string.Format("https://ohserverless98765.blob.core.windows.net/batch-files/{0}-ProductInformation.csv", entityName);
            HttpResponseMessage theResult = null;

            using (HttpClient theClient = new HttpClient())
            {
                var pocoObject = new {
                    orderHeaderDetailsCSVUrl = file1,
                    orderLineItemsCSVUrl = file2,
                    productInformationCSVUrl = file3
                };


                string json = JsonConvert.SerializeObject(pocoObject);
                StringContent data = new StringContent(json, System.Text.Encoding.UTF8, "application/json");
                theClient.BaseAddress = new Uri("https://serverlessohmanagementapi.trafficmanager.net");
                theResult = await theClient.PostAsync("/api/order/combineOrderContent", data);
            }

            var content = await theResult.Content.ReadAsStringAsync();
            //store json to document db after


            return theResult;
        }

    }
    [JsonObject(MemberSerialization.OptIn)]
    public class Counter
    {
        [JsonProperty("value")]
        public int Value { get; set; }

        public void Add(int amount)
        {
            this.Value += amount;
        }

        public Task Reset()
        {
            this.Value = 0;
            return Task.CompletedTask;
        }

        public Task<int> Get()
        {
            return Task.FromResult(this.Value);
        }

        public void Delete()
        {
            Entity.Current.DeleteState();
        }

        [FunctionName(nameof(Counter))]
        public static Task Run([EntityTrigger] IDurableEntityContext ctx)
            => ctx.DispatchAsync<Counter>();
    }
}
