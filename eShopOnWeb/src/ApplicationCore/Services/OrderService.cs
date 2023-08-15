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

namespace Microsoft.eShopWeb.ApplicationCore.Services;

public class OrderService : IOrderService
{
    private readonly IRepository<Order> _orderRepository;
    private readonly IUriComposer _uriComposer;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IRepository<Basket> _basketRepository;
    private readonly IRepository<CatalogItem> _itemRepository;

    public OrderService(
        IRepository<Basket> basketRepository,
        IRepository<CatalogItem> itemRepository,
        IRepository<Order> orderRepository,
        IUriComposer uriComposer,
        IHttpClientFactory httpClientFactory
    )
    {
        _orderRepository = orderRepository;
        _uriComposer = uriComposer;
        _httpClientFactory = httpClientFactory;
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
                var orderItem = new OrderItem(
                    itemOrdered,
                    basketItem.UnitPrice,
                    basketItem.Quantity
                );
                return orderItem;
            })
            .ToList();

        var order = new Order(basket.BuyerId, shippingAddress, items);

        await _orderRepository.AddAsync(order);

        await SendOrderItemsReservationAsync(order);
    }

    private async Task SendOrderItemsReservationAsync(Order order)
    {
        var orderReservationItems = order.OrderItems
            .Select(item => new OrderItemReservation(item.Id, item.Units))
            .ToList();

        var orderReservation = new OrderReservation(order.Id, orderReservationItems);

        var orderReservationJson = new StringContent(
            JsonSerializer.Serialize(orderReservation),
            Encoding.UTF8,
            Application.Json
        );

        var httpClient = _httpClientFactory.CreateClient("OrderItemsReserverClient");
        await httpClient.PostAsync("", orderReservationJson);
    }
}
