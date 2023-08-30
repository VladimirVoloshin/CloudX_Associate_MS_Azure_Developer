using System.Text;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace OrderItemsReserver;

public class OrderItemsReserverFunction
{
    private readonly ILogger _logger;

    public OrderItemsReserverFunction(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<OrderItemsReserverFunction>();
    }

    [Function("OrderItemsReserverFunction")]
    public HttpResponseData Run([HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");

        var requestBody = new StreamReader(req.Body).ReadToEnd();
        var orderRequest = JsonConvert.DeserializeObject<OrderReservation>(requestBody);

        string Connection = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
        string containerName = Environment.GetEnvironmentVariable("ContainerName");

        var blobClient = new BlobContainerClient(Connection, containerName);
        blobClient.CreateIfNotExists();

        var blob = blobClient.GetBlobClient($"Order-{orderRequest.OrderId}.json");

        byte[] byteArray = Encoding.ASCII.GetBytes(requestBody);
        Stream stream = new MemoryStream(byteArray);
        blob.Upload(stream);

        var response = req.CreateResponse();
        response.Headers.Add("Content-Type", "text/plain; charset=utf-8");
        response.WriteString($"Order:{orderRequest.OrderId} uploaded successfylly");
        return response;
    }

}

