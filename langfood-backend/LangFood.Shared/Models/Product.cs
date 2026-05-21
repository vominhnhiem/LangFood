using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace LangFood.Shared.Models
{
    public class Product
    {
        public int Id { get; set; }
        public int ShopId { get; set; }
        public int CategoryId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }
        public bool IsDeleted { get; set; } = false;
        public int Status { get; set; } = 0;
        public bool IsAvailable { get; set; } = true;

        [ForeignKey("CategoryId")]
        [JsonIgnore]
        public virtual Category? Category { get; set; }

        [ForeignKey("ShopId")]
        [JsonIgnore]
        public virtual Shop? Shop { get; set; }

        // --- THÊM DÒNG NÀY ---
        public virtual ICollection<ProductOptionGroup> OptionGroups { get; set; } = new List<ProductOptionGroup>();
    }
}