using System.Collections.Generic;

namespace Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;

public class OrderCreatedMessage
{
    public OrderCreatedMessage(int orderId, List<OrderItemCreatedMessage> orderRequestItems)
    {
        OrderId = orderId;
        OrderRequestItems = orderRequestItems;
    }
    public int OrderId { get; }
    public List<OrderItemCreatedMessage> OrderRequestItems { get;}
}

public class OrderItemCreatedMessage
{
    public OrderItemCreatedMessage(int itemId, int quantity)
    {
        ItemId = itemId;
        Quantity = quantity;
    }
    public int ItemId { get;  }
    public int Quantity { get; }

}
