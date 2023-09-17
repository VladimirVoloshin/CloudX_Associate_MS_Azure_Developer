using System.Net.Http;
using System.Text;
using Azure.Core;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace OrderItemsReserver;

public class OrderReserveFunction
{
    private readonly ILogger _logger;
    private readonly IHttpClientFactory _httpClientFactory;

    public OrderReserveFunction(ILoggerFactory loggerFactory, IHttpClientFactory httpClientFactory)
    {
        _logger = loggerFactory.CreateLogger<OrderReserveFunction>();
        _httpClientFactory = httpClientFactory;
    }

    [Function("OrderReserveFunction")]
    public void Run([ServiceBusTrigger("ordercreatedqueue", Connection = "OrderCreatedConnectionString")] string orderCreatedMessage)
    {
        _logger.LogInformation($"C# ServiceBus queue trigger function processed message: {orderCreatedMessage}");
        var orderRequest = JsonConvert.DeserializeObject<OrderCreatedMessage>(orderCreatedMessage);
        if (orderRequest == null)
        {
            _logger.LogError("Unable to deserialize orderRequesst");
            return;
        }

        var connection = Environment.GetEnvironmentVariable("AzureWebJobsStorage");
        var containerName = Environment.GetEnvironmentVariable("ContainerName");
        _logger.LogInformation($"Container connection string:{connection}");

        try
        {
            BlobClientOptions blobOptions = new BlobClientOptions()
            {
                Retry = {
                Delay = TimeSpan.FromSeconds(1),
                MaxRetries = 3,
                Mode = RetryMode.Exponential,
                MaxDelay = TimeSpan.FromSeconds(5),
                NetworkTimeout = TimeSpan.FromSeconds(10)
            },
            };

            var blobClient = new BlobContainerClient(connection, containerName, blobOptions);

            blobClient.CreateIfNotExists();

            var blob = blobClient.GetBlobClient($"Order-{orderRequest.OrderId}.json");

            byte[] byteArray = Encoding.ASCII.GetBytes(orderCreatedMessage);
            Stream stream = new MemoryStream(byteArray);

            blob.Upload(stream);
        }
        catch (Exception ex)
        {
            var emailMessage = $"Unable to add order to az blob storage:<br><b>{orderCreatedMessage}</b> <br><br>Reason: <br><i>{ex.Message}<i>";
            _logger.LogError(emailMessage);
            SendFailureEmail(emailMessage);
            throw;
        }
    }

    private void SendFailureEmail(string message)
    {
        _logger.LogInformation($"Sending failure message: {message}");
        var httpClient = _httpClientFactory.CreateClient();

        var emailSendUrl = Environment.GetEnvironmentVariable("EmailFailureServiceUrl");
        var httpResponseMessage = httpClient
            .PostAsync(emailSendUrl, new StringContent(message))
            .GetAwaiter().GetResult();

        if (!httpResponseMessage.IsSuccessStatusCode)
        {
            _logger.LogError("Unable to send failure email", httpResponseMessage);
        }
    }
}
