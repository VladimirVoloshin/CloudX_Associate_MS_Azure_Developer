using System.Net;
using Microsoft.Azure.Cosmos;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace DeliveryOrderProcessor;

public class DeliveryOrderProcessorFunction
{
    private readonly ILogger _logger;

    public DeliveryOrderProcessorFunction(ILoggerFactory loggerFactory)
    {
        _logger = loggerFactory.CreateLogger<DeliveryOrderProcessorFunction>();
    }

    [Function("DeliveryOrderProcessorFunction")]
    public HttpResponseData Run([HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequestData req)
    {
        _logger.LogInformation("C# HTTP trigger function processed a request.");

        var response = req.CreateResponse();
        response.Headers.Add("Content-Type", "text/plain; charset=utf-8");

        var orderStr = new StreamReader(req.Body).ReadToEnd();
        var order = JsonConvert.DeserializeObject<OrderDeliveryProcess>(orderStr);
        if (order == null || order.OrderDeliveryItems == null)
        {
            response.StatusCode = HttpStatusCode.BadRequest;
            response.WriteString($"Order invalid format:{orderStr}");
            return response;
        }

        var client = new CosmosClient(connectionString: Environment.GetEnvironmentVariable("DELIVERY_ORDER_PROCESSOR_DB_CONNECTION"));
        var container = client
            .GetDatabase(Environment.GetEnvironmentVariable("DELIVERY_ORDER_PROCESSOR_DB_NAME"))
            .GetContainer(Environment.GetEnvironmentVariable("DELIVERY_ORDER_PROCESSOR_CONTAINER_NAME"));

        try
        {
            var dbResult = container.CreateItemAsync(order).ConfigureAwait(false).GetAwaiter().GetResult();
            response.StatusCode = dbResult.StatusCode;
            return response;

        }
        catch (Exception e)
        {
            response.StatusCode=HttpStatusCode.InternalServerError;
            response.WriteString(e.Message);
            return response;
        }
    }
}
