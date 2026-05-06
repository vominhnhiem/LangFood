using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFoodBackend.Models
{
    public class RoleRequest
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [ForeignKey(nameof(UserId))]
        public virtual User User { get; set; } = null!;

        [Required]
        public int RequestType { get; set; } // 1: Seller, 2: Shipper

        [StringLength(500)]
        public string? ImageProof { get; set; }

        [StringLength(200)]
        public string? ShopName { get; set; }

        [StringLength(500)]
        public string? ShopAddress { get; set; }

        public int Status { get; set; } = 0; // 0: Pending, 1: Approved, 2: Rejected

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
