using System.Text.Json.Serialization; // Thêm dòng này
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class Order
    {
        public int Id { get; set; }
        public string BuyerId { get; set; } = string.Empty;
        public string? BuyerName { get; set; }
        public int ShopId { get; set; }
        
        public int? Leg1ShipperId { get; set; } // Shipper ngoại khu (từ Quán đến cổng KTX)
        
        public int? Leg2ShipperId { get; set; } // Shipper nội khu (từ chốt/KTX vào phòng)
        
        public int DeliveryStage { get; set; } = 0; // 0: ShippingExternal, 1: WaitingAtGate, 2: ShippingInternal

        public string Status { get; set; } = "Pending";
        public decimal TotalAmount { get; set; }
        public decimal ShippingFee { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? DeliveredAt { get; set; }
        public string? DeliveryBuilding { get; set; }

        [JsonIgnore] // THÊM DÒNG NÀY
        [ForeignKey("BuyerId")]
        public virtual User? Buyer { get; set; }

        [JsonIgnore]
        [ForeignKey("ShopId")]
        public virtual Shop? Shop { get; set; }

        [JsonIgnore]
        [ForeignKey("Leg1ShipperId")]
        public virtual Shipper? Leg1Shipper { get; set; }

        [JsonIgnore]
        [ForeignKey("Leg2ShipperId")]
        public virtual Shipper? Leg2Shipper { get; set; }

        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}