using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class Order
    {
        public int Id { get; set; }
        public string BuyerId { get; set; } = string.Empty;
        public string? BuyerName { get; set; }
        public int ShopId { get; set; }

        // CHỈ DÙNG 1 SHIPPER DUY NHẤT
        public int? ShipperId { get; set; }

        public string Status { get; set; } = "Pending";
        public decimal TotalAmount { get; set; }
        public decimal ShippingFee { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? DeliveredAt { get; set; }

        // THÔNG TIN GIAO HÀNG CHI TIẾT
        public string? DeliveryBuilding { get; set; }
        public string? DeliveryRoom { get; set; }

        [JsonIgnore]
        [ForeignKey("BuyerId")]
        public virtual User? Buyer { get; set; }

        [JsonIgnore]
        [ForeignKey("ShopId")]
        public virtual Shop? Shop { get; set; }

        // LIÊN KẾT ĐẾN SHIPPER (Sửa chỗ này để hết lỗi ở DbContext)
        [JsonIgnore]
        [ForeignKey("ShipperId")]
        public virtual Shipper? Shipper { get; set; }

        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}