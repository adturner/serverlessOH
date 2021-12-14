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
    public static class CreateRating
    {
        [FunctionName("CreateRating")]
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
            [CosmosDB(
                databaseName: "products",
                collectionName: "ratings",
                ConnectionStringSetting = "CosmosDBConnection")]out dynamic document,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            string requestBody = new StreamReader(req.Body).ReadToEnd();
            dynamic data = JsonConvert.DeserializeObject(requestBody);

            Rating theRating = new Rating();
            theRating.id = Guid.NewGuid().ToString();
            theRating.userId = data.userId;
            theRating.productId = data.productId;
            theRating.timestamp = DateTime.Now.ToUniversalTime().ToLongDateString();
            theRating.locationName = data.locationName;
            theRating.rating = Convert.ToInt32(data.rating);
            theRating.userNotes = data.userNotes;

            string responseMessage = JsonConvert.SerializeObject(theRating);
            document = new
            {
                id = theRating.id,
                userId = theRating.userId,
                productId = theRating.productId,
                timestamp = theRating.timestamp,
                locationName = theRating.locationName,
                rating = theRating.rating,
                userNotes = theRating.userNotes
            };

            return new OkObjectResult(responseMessage);
        }
    }
}
