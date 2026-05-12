using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace LangFood.Shared.ViewModels
{
    public class CreatePartnerViewModel
    {
        [Required(ErrorMessage = "Số điện thoại là bắt buộc")]
        [Phone(ErrorMessage = "Số điện thoại không đúng định dạng")]
        [Display(Name = "Số điện thoại (Tài khoản)")]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required(ErrorMessage = "Họ tên là bắt buộc")]
        [StringLength(100, ErrorMessage = "Họ tên không được quá 100 ký tự")]
        [Display(Name = "Họ tên chủ quán")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mật khẩu là bắt buộc")]
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
        [DataType(DataType.Password)]
        [Display(Name = "Mật khẩu")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Tên gian hàng là bắt buộc")]
        [StringLength(255)]
        [Display(Name = "Tên quán ăn")]
        public string ShopName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Địa chỉ là bắt buộc")]
        [StringLength(500)]
        [Display(Name = "Địa chỉ quán")]
        public string Address { get; set; } = string.Empty;

        [Display(Name = "Mô tả quán")]
        public string? Description { get; set; }

        [Display(Name = "Ảnh đại diện quán")]
        public IFormFile? ShopImage { get; set; }
    }
}
