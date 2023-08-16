// Ignore Spelling: req

using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Azure.Storage.Blobs;
using static System.Net.Mime.MediaTypeNames;
using System.Text;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;

namespace OrderItemsReserver;

public static class OrderItemsReserverFunction
{
    [FunctionName("OrderItemsReserverFunction")]
    public static async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req,
        ILogger log)
    {
        log.LogInformation("C# HTTP trigger function processed a request.");

        req.EnableBuffering(bufferThreshold: 1024 * 45, bufferLimit: 1024 * 100);

        string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
        var orderRequest = JsonConvert.DeserializeObject<OrderReservation>(requestBody);

        string Connection = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
        string containerName = Environment.GetEnvironmentVariable("ContainerName");

        var blobClient = new BlobContainerClient(Connection, containerName);
        blobClient.CreateIfNotExists();

        var blob = blobClient.GetBlobClient($"Order-{orderRequest.OrderId}.json");
        try
        {
            byte[] byteArray = Encoding.ASCII.GetBytes(requestBody);
            Stream stream = new MemoryStream(byteArray);
            await blob.UploadAsync(stream);

        }
        catch (Exception)
        {

            throw;
        }
        return new OkObjectResult($"Order:{orderRequest.OrderId} uploaded successfylly");
    }
}
