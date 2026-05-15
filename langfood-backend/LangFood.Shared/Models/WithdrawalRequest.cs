using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    /// <summary>
    /// Lệnh rút tiền thật của Quán hoặc Shipper.
    /// Admin sẽ thực hiện chuyển khoản thủ công rồi upload ảnh bill xác nhận.
    /// </summary>
    public class WithdrawalRequest
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string UserId { get; set; } = string.Empty;

        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal Amount { get; set; }

        // Thông tin ngân hàng nhận tiền
        [StringLength(100)]
        public string BankName { get; set; } = string.Empty;

        [StringLength(50)]
        public string BankAccountNumber { get; set; } = string.Empty;

        [StringLength(150)]
        public string BankAccountName { get; set; } = string.Empty;

        // Ghi chú của người dùng
        public string? Note { get; set; }

        // Trạng thái: 0 = Chờ xử lý, 1 = Đã chuyển khoản, 2 = Từ chối
        public int Status { get; set; } = 0;

        // URL ảnh bill chuyển khoản do Admin upload (sau khi đã thực hiện)
        public string? AdminBillImageUrl { get; set; }

        // Ghi chú từ Admin (lý do từ chối hoặc ghi chú thêm)
        public string? AdminNote { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? ProcessedAt { get; set; }

        [ForeignKey("UserId")]
        public virtual User? User { get; set; }
    }
}
