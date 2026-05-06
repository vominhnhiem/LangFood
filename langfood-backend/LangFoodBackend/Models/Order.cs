using System.Text.Json.Serialization; // Thêm dòng này
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFoodBackend.Models
{
    public class Order
    {
        public int Id { get; set; }
        public string BuyerId { get; set; } = string.Empty;
        public string? BuyerName { get; set; }
        public string? ShipperId { get; set; } // Shipper nội khu (từ chốt/KTX vào phòng)
        
        public string? ExternalShipperId { get; set; } // Shipper ngoại khu (từ Quán đến cổng KTX)
        
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

        [JsonIgnore] // THÊM DÒNG NÀY
        [ForeignKey("ShipperId")]
        public virtual User? Shipper { get; set; }

        [JsonIgnore]
        [ForeignKey("ExternalShipperId")]
        public virtual User? ExternalShipper { get; set; }

        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}