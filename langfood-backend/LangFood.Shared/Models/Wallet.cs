using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LangFood.Shared.Models
{
    public class Wallet
    {
        [Key]
        public int Id { get; set; } // Là kiểu int

        [Required]
        public string UserId { get; set; }  // Liên kết với bảng Users
        public decimal Balance { get; set; } = 0;
        public string? QrCodeUrl { get; set; } // Lưu link ảnh QR nhận tiền
        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        // Navigation property
        public virtual User User { get; set; }
    }
}
