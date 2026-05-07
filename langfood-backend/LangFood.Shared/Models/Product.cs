using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class Product
    {
        public int Id { get; set; }
        public string SellerId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        [Column(TypeName = "decimal(18,2)")] // Thêm dòng này Nhiệm nhé
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }
        public int Status { get; set; } = 0;
        public bool IsAvailable { get; set; } = true;
        // Mở file Product.cs và thêm các dòng này vào
        public int CategoryId { get; set; }

        [ForeignKey("CategoryId")]
        public virtual Category? Category { get; set; }
        // Tạo khóa ngoại nối với Seller (User)
        [ForeignKey("SellerId")]
        public virtual User? Seller { get; set; }
    }
}