using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using Ardalis.GuardClauses;
using Microsoft.eShopWeb.ApplicationCore.Entities;
using Microsoft.eShopWeb.ApplicationCore.Entities.BasketAggregate;
using Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;
using Microsoft.eShopWeb.ApplicationCore.Interfaces;
using Microsoft.eShopWeb.ApplicationCore.Specifications;
using System.Net.Http;
using System.Text.Json;
using System.Text;
using static System.Net.Mime.MediaTypeNames;
using Microsoft.Extensions.Configuration;
using System.Threading;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Logging;

namespace Microsoft.eShopWeb.ApplicationCore.Services;

public class OrderService : IOrderService
{
    private readonly IRepository<Order> _orderRepository;
    private readonly IUriComposer _uriComposer;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<OrderService> _log;
    private readonly IRepository<Basket> _basketRepository;
    private readonly IRepository<CatalogItem> _itemRepository;

    public OrderService(
        IRepository<Basket> basketRepository,
        IRepository<CatalogItem> itemRepository,
        IRepository<Order> orderRepository,
        IUriComposer uriComposer,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<OrderService> log
    )
    {
        _orderRepository = orderRepository;
        _uriComposer = uriComposer;
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _log = log;
        _basketRepository = basketRepository;
        _itemRepository = itemRepository;
    }

    public async Task CreateOrderAsync(int basketId, Address shippingAddress)
    {
        var basketSpec = new BasketWithItemsSpecification(basketId);
        var basket = await _basketRepository.FirstOrDefaultAsync(basketSpec);

        Guard.Against.Null(basket, nameof(basket));
        Guard.Against.EmptyBasketOnCheckout(basket.Items);

        var catalogItemsSpecification = new CatalogItemsSpecification(
            basket.Items.Select(item => item.CatalogItemId).ToArray()
        );
        var catalogItems = await _itemRepository.ListAsync(catalogItemsSpecification);

        var items = basket.Items
            .Select(basketItem =>
            {
                var catalogItem = catalogItems.First(c => c.Id == basketItem.CatalogItemId);
                var itemOrdered = new CatalogItemOrdered(
                    catalogItem.Id,
                    catalogItem.Name,
                    _uriComposer.ComposePicUri(catalogItem.PictureUri)
                );
                return new OrderItem(
                    itemOrdered,
                    basketItem.UnitPrice,
                    basketItem.Quantity
                );
            })
            .ToList();

        var order = new Order(basket.BuyerId, shippingAddress, items);

        await _orderRepository.AddAsync(order);

        if (Convert.ToBoolean(_configuration["OrderItemsReserver:IsEnabled"]))
        {
            await SendOrderItemsReservationAsync(order);
        }

        if (Convert.ToBoolean(_configuration["DeliveryOrderProcessor:IsEnabled"]))
        {
            await SendDeliveryOrderProcessingAsync(order);
        }
    }

    //private async Task SendOrderItemsReservationAsync(Order order)
    //{
    //    var orderReservationItems = order.OrderItems
    //        .Select(item => new OrderItemReservation(item.Id, item.Units))
    //        .ToList();

    //    var orderReservation = new OrderReservation(order.Id, orderReservationItems);

    //    var orderReservationJson = new StringContent(
    //        JsonSerializer.Serialize(orderReservation),
    //        Encoding.UTF8,
    //        Application.Json
    //    );

    //    var httpClient = _httpClientFactory.CreateClient("OrderItemsReserverClient");
    //    await httpClient.PostAsync("", orderReservationJson);
    //}

    private async Task SendOrderItemsReservationAsync(Order order)
    {
        _log.LogInformation("Try to send order items reservation message");
        try
        {
            var serviceBusConnStr = _configuration["Messaging:OrderServiceBus:ConnectionString"];
            var orderCreatedQueue = _configuration["Messaging:OrderServiceBus:OrderCreatedQueue"];
            _log.LogInformation($"Service bus connection string:{serviceBusConnStr}");
            _log.LogInformation($"Order created queue:{orderCreatedQueue}");

            await using var client = new ServiceBusClient(serviceBusConnStr);
            ServiceBusSender sender = client.CreateSender(orderCreatedQueue);


            var orderReservationItems = order.OrderItems
                .Select(item => new OrderItemCreatedMessage(item.Id, item.Units))
                .ToList();

            var orderReservation = new OrderCreatedMessage(order.Id, orderReservationItems);

            //var orderReservationJson = new StringContent(
            //    JsonSerializer.Serialize(orderReservation),
            //    Encoding.UTF8,
            //    Application.Json
            //);

            var message = new ServiceBusMessage(JsonSerializer.Serialize(orderReservation));
            await sender.SendMessageAsync(message);
            //var httpClient = _httpClientFactory.CreateClient("OrderItemsReserverClient");
            //await httpClient.PostAsync("", orderReservationJson);
        }
        catch (Exception e)
        {
            _log.LogError("Send Items reserving message error ", e);
            throw;
        }
    }

    private async Task SendDeliveryOrderProcessingAsync(Order order)
    {
        var orderDelivery = new OrderDeliveryProcess(
            order.Id.ToString(),
            order.ShipToAddress,
            order.OrderItems.Select(x => new OrderDeliveryItem(x.Id, x.Units)).ToList(),
            order.Total());

        var orderJson = new StringContent(
            JsonSerializer.Serialize(orderDelivery),
            Encoding.UTF8,
            Application.Json
        );

        var httpClient = _httpClientFactory.CreateClient("DeliveryOrderProcessorClient");
        await httpClient.PostAsync("", orderJson);
    }
}
