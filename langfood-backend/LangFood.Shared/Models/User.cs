using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace LangFood.Shared.Models
{
    public class User
    {
        [Key]
        public string Id { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public int RoleId { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }

        public int? BuildingId { get; set; }

        [ForeignKey("BuildingId")]
        public virtual Building? Building { get; set; }

        public string? KtxRoom { get; set; }
        public bool IsVerifiedResident { get; set; }
        public string? StudentCardImageUrl { get; set; }
        public string? AvatarUrl { get; set; }

        public bool IsApproved { get; set; } = false;

        [StringLength(20)]
        public string? CccdNumber { get; set; }

        [NotMapped]
        public string? ShopName { get; set; }

        [NotMapped]
        public string? ShopAddress { get; set; }

        [JsonIgnore]
        public virtual ICollection<Product> Products { get; set; } = new List<Product>();
        [JsonIgnore]
        public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
        [JsonIgnore]
        public virtual ICollection<RoleRequest> RoleRequests { get; set; } = new List<RoleRequest>();

        // KHÔNG DÙNG JsonIgnore ở đây để Android nhận được dữ liệu
        public virtual Shop? Shop { get; set; }

        public virtual Shipper? Shipper { get; set; }

        public virtual Wallet? Wallet { get; set; }
    }
}