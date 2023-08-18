using System.Collections.Generic;
using Newtonsoft.Json;

namespace Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;
public class OrderDeliveryProcess
{
    public OrderDeliveryProcess(string id, Address shippingAddress, List<OrderDeliveryItem> orderDeliveryItems, decimal finalPrice)
    {

        Id = id;
        ShippingAddress = shippingAddress;
        OrderDeliveryItems = orderDeliveryItems;
        FinalPrice = finalPrice;
    }

    [JsonProperty(PropertyName = "id")]
    public string Id { get; }
    public Address ShippingAddress { get; }
    public List<OrderDeliveryItem> OrderDeliveryItems { get; }
    public decimal FinalPrice { get; }

}

public class OrderDeliveryItem
{
    public OrderDeliveryItem(int id, int quantity)
    {
        Id = id;
        Quantity = quantity;
    }

    public int Id { get; }
    public int Quantity { get;}
}
