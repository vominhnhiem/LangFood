using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class RoleRequest
    {
        [Key]
        public int Id { get; set; }
        public string UserId { get; set; }
        public int RequestType { get; set; } // 1: Seller, 2: Shipper

        public string? ImageProof { get; set; } // Đường dẫn ảnh thẻ SV
        public string? ShopName { get; set; }   // Dùng để lưu "MSSV: 12345"
        public string? ShopAddress { get; set; }

        public int Status { get; set; } // 0: Pending, 1: Approved, 2: Rejected
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
