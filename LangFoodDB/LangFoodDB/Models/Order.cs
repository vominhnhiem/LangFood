using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFoodDB.Models
{
    public enum OrderStatus
    {
        Pending,
        Processing,
        ShippingExternal, // Đang giao tới cổng (Chặng 1)
        WaitingAtGate,    // Chờ tại cổng KTX
        ShippingInternal, // Shipper SV đang giao vào phòng (Chặng 2)
        Delivered,
        Cancelled
    }

    public class Order
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int BuyerId { get; set; }

        public int? ExternalShipperId { get; set; } // Shipper của Quán (Chặng 1)

        public int? ShipperId { get; set; } // Shipper Sinh Viên Làng Food (Chặng 2)
        
        public int DeliveryStage { get; set; } = 0; // 0: Quán đang làm, 1: Giao chặng 1, 2: Tới cổng, 3: Giao chặng 2, 4: Hoàn thành

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; }

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal ShippingFee { get; set; }

        [Required]
        public OrderStatus Status { get; set; } = OrderStatus.Pending;

        public DateTime OrderDate { get; set; } = DateTime.UtcNow;

        [StringLength(500)]
        public string? Note { get; set; }

        public virtual User Buyer { get; set; } = null!;

        public virtual User? Shipper { get; set; }

        public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    }
}
