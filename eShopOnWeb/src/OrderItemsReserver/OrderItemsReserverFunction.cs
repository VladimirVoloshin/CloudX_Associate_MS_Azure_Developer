using System.Text;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Azure.Messaging.ServiceBus;

namespace OrderItemsReserver;

public class OrderItemsReserverFunction
{
    private readonly ILogger _logger;
    private readonly IConfiguration _configuration;

    public OrderItemsReserverFunction(ILoggerFactory loggerFactory, IConfiguration configuration)
    {
        _logger = loggerFactory.CreateLogger<OrderItemsReserverFunction>();
        _configuration = configuration;
    }

    [Function("OrderItemsReserverFunction")]
    public void Run([ServiceBusTrigger(queueName:"Messaging:OrderServicebus:OrderCreatedQueue", Connection = "Messaging:OrderServicebus:ConnectionString")]
    string orderCreatedMessage,
    Int32 deliveryCount,
    DateTime enqueuedTimeUtc,
    string messageId,
    ILogger log)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");

        var requestBody = new StreamReader(orderCreatedMessage).ReadToEnd();
        _logger.LogInformation("Function received a request: " + requestBody);

        var orderRequest = JsonConvert.DeserializeObject<OrderCreatedMessage>(requestBody);
        if (orderRequest == null)
        {
            _logger.LogError("Unable to desirialize orderRequest");
            return;
        }

        var Connection = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
        var containerName = Environment.GetEnvironmentVariable("ContainerName");

        var blobClient = new BlobContainerClient(Connection, containerName);
        blobClient.CreateIfNotExists();

        var blob = blobClient.GetBlobClient($"Order-{orderRequest.OrderId}.json");

        byte[] byteArray = Encoding.ASCII.GetBytes(requestBody);
        Stream stream = new MemoryStream(byteArray);
        blob.Upload(stream);

    }

}

