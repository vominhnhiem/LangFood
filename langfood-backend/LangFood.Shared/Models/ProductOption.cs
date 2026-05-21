using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace LangFood.Shared.Models
{
    public class ProductOption
    {
        [Key]
        public int Id { get; set; }

        public int OptionGroupId { get; set; }

        [Required]
        [StringLength(255)]
        public string Name { get; set; } = string.Empty; // VD: "Thêm trứng", "Ít cay"

        [Column(TypeName = "decimal(18,2)")]
        public decimal AdditionalPrice { get; set; } // Giá cộng thêm

        public bool IsAvailable { get; set; } = true; // Còn hàng hay không

        [ForeignKey("OptionGroupId")]
        [JsonIgnore]
        public virtual ProductOptionGroup? OptionGroup { get; set; }
    }
}