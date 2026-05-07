using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace LangFood.Shared.Models
{
    public class User
    {
        public string Id { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public int RoleId { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public string? KtxBuilding { get; set; }
        public string? KtxRoom { get; set; }
        public bool IsVerifiedResident { get; set; }
        public string? StudentCardImageUrl { get; set; }
        public string? AvatarUrl { get; set; }

        // --- NEW FIELDS FOR ONBOARDING ---
        public bool IsApproved { get; set; } = false;
        public int AccountType { get; set; } = 0; // 0: Student, 1: Merchant
        
        [StringLength(20)]
        public string? CccdNumber { get; set; }

        [NotMapped]
        public string? ShopName { get; set; }
        
        [NotMapped]
        public string? ShopAddress { get; set; }

        // --- THÊM CÁC DÒNG NÀY ĐỂ LIÊN KẾT CHẶT CHẼ ---
        [JsonIgnore]
        public virtual ICollection<Product> Products { get; set; } = new List<Product>();
        [JsonIgnore]
        public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
        [JsonIgnore]
        public virtual ICollection<RoleRequest> RoleRequests { get; set; } = new List<RoleRequest>();
    }
}