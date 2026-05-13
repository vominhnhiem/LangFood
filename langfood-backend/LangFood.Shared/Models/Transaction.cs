using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class Transaction
    {
        [Key]
        public int Id { get; set; }
        [Required]
        public int WalletId { get; set; }
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }
        public string Type { get; set; } // "DEPOSIT", "WITHDRAW"...
        public string Description { get; set; }

        // TRẠNG THÁI: 0: Chờ duyệt (Pending), 1: Thành công (Success), 2: Thất bại (Rejected)
        public int Status { get; set; } = 0;

        public int? OrderId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        // Trong Transaction.cs
        [ForeignKey("WalletId")]
        public virtual Wallet? Wallet { get; set; }

        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }
    }
}