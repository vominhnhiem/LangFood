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
        public int? BuildingId { get; set; }
        public int? ShipperId { get; set; }

        public string Status { get; set; } = "Pending";
        public decimal TotalAmount { get; set; }
        public decimal ShippingFee { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? DeliveredAt { get; set; }

        public string? DeliveryBuilding { get; set; }
        public string? DeliveryRoom { get; set; }

        // 0: Cash (Tiền mặt), 1: Wallet (Ví/QR)
        public int PaymentMethod { get; set; }

        // --- Navigation Properties ---

        [JsonIgnore]
        [ForeignKey("BuyerId")]
        public virtual User? Buyer { get; set; }

        [JsonIgnore]
        [ForeignKey("ShopId")]
        public virtual Shop? Shop { get; set; }

        [JsonIgnore]
        [ForeignKey("ShipperId")]
        public virtual Shipper? Shipper { get; set; }

        [JsonIgnore]
        [ForeignKey("BuildingId")]
        public virtual Building? Building { get; set; }

        // Danh sách món ăn trong đơn
        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();

        // Danh sách lịch sử tiền tệ liên quan đến đơn này
        [JsonIgnore]
        public virtual ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    }
}