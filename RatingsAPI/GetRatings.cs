using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Collections.Generic;

namespace RatingsAPI
{
    public static class GetRatings
    {
        [FunctionName("GetRatings")]
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", Route = "GetRatings/{userId}")] HttpRequest req,
            [CosmosDB(
                databaseName: "products",
                collectionName: "ratings",
                ConnectionStringSetting = "CosmosDBConnection",
                SqlQuery = "SELECT * FROM c where c.userId = {userId}"
                //SqlQuery = "SELECT * FROM c where c.userId = 'cc20a6fb-a91f-4192-874d-132493685376'"
                //SqlQuery = "SELECT TOP 1 * FROM c"
                )] IEnumerable<Rating> ratingItems,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            if (ratingItems == null)
            {
                log.LogInformation($"ratingItem not found");
            }
            else
            {
                foreach (Rating i in ratingItems)
                {
                    log.LogInformation($"Found ratings item, UserNotes={i.userNotes}");
                }
            }
            return new OkObjectResult(ratingItems);
        }
    }
}
