using System.Text.Json.Serialization; // Thêm thư viện này
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class Wallet
    {
        [Key]
        public int Id { get; set; }

        public string UserId { get; set; } = string.Empty;

        public decimal Balance { get; set; } = 0;

        public DateTime UpdatedAt { get; set; } = DateTime.Now;

        public string? QrCodeUrl { get; set; }

        [JsonIgnore] // QUAN TRỌNG: Thêm dòng này để hết lỗi đăng nhập
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}