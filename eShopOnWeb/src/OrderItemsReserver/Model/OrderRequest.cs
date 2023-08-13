using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace OrderItemsReserver.Model;

internal class OrderRequest
{
    public int OrderId { get; set; }
    public List<OrderRequestItem> OrderRequestItems { get; set; }
}

internal class OrderRequestItem
{
    public int ItemId { get; set; }
    public int Quantity { get; set; }

}
