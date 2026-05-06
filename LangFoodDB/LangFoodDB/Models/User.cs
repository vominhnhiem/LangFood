using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFoodDB.Models
{
    public enum Role
    {
        Buyer,
        Seller,
        Shipper,
        Admin
    }

    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [StringLength(15)]
        public string Phone { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [StringLength(100)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(255)]
        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        public Role Role { get; set; } = Role.Buyer;

        [StringLength(50)]
        public string? BuildingName { get; set; }

        public bool IsApproved { get; set; } = false;

        public int AccountType { get; set; } = 0; // 0: SinhVien, 1: ExternalMerchant

        [StringLength(20)]
        public string? CccdNumber { get; set; }

        [StringLength(255)]
        public string? StudentIdCardImage { get; set; }

        [NotMapped]
        public string? ShopName { get; set; }

        [NotMapped]
        public string? ShopAddress { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        public virtual ICollection<Order> OrdersAsBuyer { get; set; } = new List<Order>();
        public virtual ICollection<Order> OrdersAsShipper { get; set; } = new List<Order>();
        public virtual ICollection<Shop> Shops { get; set; } = new List<Shop>();
    }
}
