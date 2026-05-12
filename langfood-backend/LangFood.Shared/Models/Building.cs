using System.ComponentModel.DataAnnotations;

namespace LangFood.Shared.Models
{
    public class Building
    {
        [Key]
        public int Id { get; set; }

        [Required(ErrorMessage = "Tên tòa nhà không được để trống")]
        [StringLength(100)]
        public string Name { get; set; }

        public bool IsActive { get; set; } = true;

        // Nếu muốn lưu thêm mô tả hoặc vị trí bản đồ có thể thêm ở đây
        // public string? Description { get; set; }
    }
}