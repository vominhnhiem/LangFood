using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace LangFood.Shared.Models
{
    public class Product
    {
        public int Id { get; set; }
        public int ShopId { get; set; }
        public int CategoryId { get; set; } // Đã đưa lên đầu cho gọn
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsDeleted { get; set; } = false;
        public int Status { get; set; } = 0; // 0: Pending, 1: Approved, 2: Rejected
        public bool IsAvailable { get; set; } = true;

        // --- Navigation Properties ---

        [ForeignKey("CategoryId")]
        [JsonIgnore] // Chặn vòng lặp khi trả về JSON
        public virtual Category? Category { get; set; }

        [ForeignKey("ShopId")]
        [JsonIgnore] // Chặn vòng lặp khi trả về JSON
        public virtual Shop? Shop { get; set; }
    }
}