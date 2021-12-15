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
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
                [CosmosDB(
                    databaseName: "products",
                    collectionName: "ratings",
                    //ConnectionStringSetting = "AccountEndpoint=https://serverlessohteamone.documents.azure.com:443/;AccountKey=mtpobleU4hW2a0BP79rbYPh6LC4GSYeOEQn9yrkP2jTcnjGcl0I2CHsVH1lwzLlUQ14IwlFrgfhdkCqmIqxddA==;",
                    ConnectionStringSetting = "CosmosDBConnection",
                    Id = "{Query.id}",
                    PartitionKey = "productId")] Rating ratingItem,
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

            Rating rating = new Rating();
            rating.id = ratingItem.id;
            rating.userId = ratingItem.userId;
            rating.productId = ratingItem.productId;
            rating.timestamp = ratingItem.timestamp;
            rating.locationName = ratingItem.locationName;
            rating.rating = ratingItem.rating;
            rating.userNotes = ratingItem.userNotes;

            string jsonRating = JsonConvert.SerializeObject(rating);

           // {
             //   "id": "79c2779e-dd2e-43e8-803d-ecbebed8972c",
             //   "userId": "cc20a6fb-a91f-4192-874d-132493685376",
             //   "productId": "4c25613a-a3c2-4ef3-8e02-9c335eb23204",
             //   "timestamp": "2018-05-21 21:27:47Z",
             //   "locationName": "Sample ice cream shop",
             //   "rating": 5,
             //   "userNotes": "I love the subtle notes of orange in this ice cream!"
          ///  }
            //return new OkResult();

            return new OkObjectResult(jsonRating);
        }
    }
}
