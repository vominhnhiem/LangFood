using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class OrderTest
    {
        public int Id { get; set; }

        [Required]
        public string CustomerName { get; set; } = "Khách hàng Demo";

        [Required]
        public string DeliveryAddress { get; set; } = "Sảnh KTX Khu B, Thủ Đức";

        [Required]
        public string Phone { get; set; } = "0987654321";

        public double Latitude { get; set; } = 10.8800;

        public double Longitude { get; set; } = 106.8050;

        [Column(TypeName = "decimal(18,2)")]
        public decimal TotalAmount { get; set; } = 35000;

        public string Status { get; set; } = "Ready"; // Ready, Delivering, Completed, Cancelled

        public int? ShipperId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
