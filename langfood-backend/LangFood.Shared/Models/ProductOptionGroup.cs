using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace LangFood.Shared.Models
{
    public class ProductOptionGroup
    {
        [Key]
        public int Id { get; set; }

        public int ProductId { get; set; }

        [Required]
        [StringLength(255)]
        public string Name { get; set; } = string.Empty; // VD: "Topping thêm", "Size", "Mức độ cay"

        public bool IsRequired { get; set; } = false; // Bắt buộc chọn hay không

        public int MinSelectable { get; set; } = 0;

        public int MaxSelectable { get; set; } = 1; // VD: chọn tối đa 7 món

        [ForeignKey("ProductId")]
        [JsonIgnore]
        public virtual Product? Product { get; set; }

        public virtual ICollection<ProductOption> Options { get; set; } = new List<ProductOption>();
    }
}
