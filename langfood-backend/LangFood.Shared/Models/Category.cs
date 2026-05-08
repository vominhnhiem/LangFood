using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LangFood.Shared.Models
{
    public class Category
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; }
        // Thêm dòng này vào cả 2 class Category và Product
        public bool IsDeleted { get; set; } = false;
        public string? ImageUrl { get; set; }

        // Liên kết ngược lại: Một thể loại có nhiều sản phẩm
        public virtual ICollection<Product>? Products { get; set; }
    }
}
