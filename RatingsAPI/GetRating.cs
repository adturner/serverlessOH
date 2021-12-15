using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace RatingsAPI
{
    public static class GetRating
    {
        [FunctionName("GetRating")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = "GetRating/{productId}/{ratingId}")] HttpRequest req,
                [CosmosDB(
                    databaseName: "products",
                    collectionName: "ratings",
                    ConnectionStringSetting = "CosmosDBConnection",
                    Id = "{ratingId}",
                    PartitionKey = "{productId}")] Rating ratingItem,
                ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            if (ratingItem == null)
            {
                log.LogInformation($"Product not found");
            }
            else
            {
                log.LogInformation($"Found Product, Description={ratingItem.id}");
            }

            return new OkObjectResult(ratingItem);
        }
    }
}
