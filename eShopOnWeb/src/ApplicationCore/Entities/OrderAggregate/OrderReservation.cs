using System.Collections.Generic;

namespace Microsoft.eShopWeb.ApplicationCore.Entities.OrderAggregate;

public class OrderReservation
{
    public OrderReservation(int orderId, List<OrderItemReservation> orderRequestItems)
    {
        OrderId = orderId;
        OrderRequestItems = orderRequestItems;
    }
    public int OrderId { get; }
    public List<OrderItemReservation> OrderRequestItems { get;}
}

public class OrderItemReservation
{
    public OrderItemReservation(int itemId, int quantity)
    {
        ItemId = itemId;
        Quantity = quantity;
    }
    public int ItemId { get;  }
    public int Quantity { get; }

}
