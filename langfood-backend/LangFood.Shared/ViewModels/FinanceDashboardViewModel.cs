using System;
using System.Collections.Generic;
using LangFood.Shared.Models;

namespace LangFood.Shared.ViewModels
{
    // ============================================================
    // VIEWMODEL CHO TRANG TỔNG QUAN (DASHBOARD CARDS)
    // ============================================================
    public class FinanceDashboardViewModel
    {
        // --- 4 Thẻ Dashboard ---
        public decimal TotalSystemBalance { get; set; }       // Tổng số dư trong ví TẤT CẢ user
        public decimal TotalAdminRevenue { get; set; }        // Tổng phí/hoa hồng Admin đã thu (từ các giao dịch FEE)
        public int PendingDepositCount { get; set; }          // Số lượng YC nạp tiền chờ duyệt
        public int PendingWithdrawalCount { get; set; }       // Số lượng YC rút tiền chờ xử lý

        // --- Dữ liệu cho 3 Tabs ---
        public List<DepositRequestViewModel> PendingDeposits { get; set; } = new();
        public List<WithdrawalRequestViewModel> PendingWithdrawals { get; set; } = new();
        public List<TransactionHistoryViewModel> TransactionHistory { get; set; } = new();
    }

    // ============================================================
    // VIEWMODEL CHO TAB 1: PHÊ DUYỆT NẠP TIỀN
    // ============================================================
    public class DepositRequestViewModel
    {
        public int TransactionId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string UserRole { get; set; } = string.Empty;    // "Sinh viên", "Shipper"
        public decimal Amount { get; set; }
        public string Description { get; set; } = string.Empty; // Mã giao dịch / Nội dung CK
        public string? BillImageUrl { get; set; }               // URL ảnh proof người dùng gửi lên
        public DateTime CreatedAt { get; set; }
        public int? OrderId { get; set; }
    }

    // ============================================================
    // VIEWMODEL CHO TAB 2: YÊU CẦU RÚT TIỀN
    // ============================================================
    public class WithdrawalRequestViewModel
    {
        public int WithdrawalId { get; set; }
        public string UserId { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string UserRole { get; set; } = string.Empty;   // "Quán ăn", "Shipper"
        public decimal Amount { get; set; }
        public decimal CurrentWalletBalance { get; set; }       // Số dư ví hiện tại để Admin kiểm tra
        public string BankName { get; set; } = string.Empty;
        public string BankAccountNumber { get; set; } = string.Empty;
        public string BankAccountName { get; set; } = string.Empty;
        public string? Note { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // ============================================================
    // VIEWMODEL CHO TAB 3: LỊCH SỬ BIẾN ĐỘNG SỐ DƯ
    // ============================================================
    public class TransactionHistoryViewModel
    {
        public int TransactionId { get; set; }
        public string UserFullName { get; set; } = string.Empty;
        public string UserRole { get; set; } = string.Empty;
        public decimal Amount { get; set; }            // Dương: Cộng tiền, Âm: Trừ tiền
        public string Type { get; set; } = string.Empty;
        public string TypeLabel { get; set; } = string.Empty; // "Nạp tiền", "Thanh toán đơn", ...
        public string Description { get; set; } = string.Empty;
        public int Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? OrderId { get; set; }
        public bool IsPositive => Amount >= 0;
    }
}
