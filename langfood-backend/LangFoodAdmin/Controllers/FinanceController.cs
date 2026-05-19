using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using LangFood.Shared.Models;
using LangFood.Shared.ViewModels;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;

namespace LangFoodAdmin.Controllers
{
    public class FinanceController : Controller
    {
        private readonly LangFoodDbContext _context;
        private readonly IWebHostEnvironment _env;

        // Nhãn hiển thị loại giao dịch
        private static readonly Dictionary<string, string> TypeLabels = new()
        {
            ["DEPOSIT"] = "Nạp tiền vào ví",
            ["WITHDRAW"] = "Rút tiền về ngân hàng",
            ["ORDER_PAYMENT"] = "Thanh toán đơn hàng",
            ["REFUND"] = "Hoàn tiền",
            ["FEE"] = "Phí hệ thống"
        };

        // Hàm helper để lấy nhãn vai trò
        private static string GetRoleLabel(int? roleId) => roleId switch
        {
            1 => "Super Admin",
            2 => "Quán ăn",
            3 => "Sinh viên",
            4 => "Shipper",
            _ => "Người dùng"
        };

        public FinanceController(LangFoodDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // ==========================================
        // 1. TRANG TỔNG QUAN (INDEX)
        // ==========================================
        public async Task<IActionResult> Index()
        {
            var vm = new FinanceDashboardViewModel();

            // 1. Thẻ thống kê (Chạy trực tiếp trên SQL ok)
            vm.TotalSystemBalance = await _context.Wallets.SumAsync(w => w.Balance);
            vm.TotalAdminRevenue = await _context.Transactions
                .Where(t => (t.Type == "FEE" || t.Type == "ADMIN_FEE") && t.Status == 1)
                .SumAsync(t => t.Amount);

            vm.PendingDepositCount = await _context.Transactions
                .CountAsync(t => t.Type == "DEPOSIT" && t.Status == 0);
            vm.PendingWithdrawalCount = await _context.WithdrawalRequests
                .CountAsync(w => w.Status == 0);

            // 2. Tab 1: Yêu cầu nạp tiền
            // Lấy data thô từ DB về trước
            var rawDeposits = await _context.Transactions
                .Where(t => t.Type == "DEPOSIT" && t.Status == 0)
                .Include(t => t.Wallet).ThenInclude(w => w.User)
                .ToListAsync();

            // Map data thô sang ViewModel bằng C# (trên Client)
            vm.PendingDeposits = rawDeposits.Select(t => new DepositRequestViewModel
            {
                TransactionId = t.Id,
                UserFullName = t.Wallet?.User?.FullName ?? t.Wallet?.User?.Username ?? "N/A",
                UserRole = GetRoleLabel(t.Wallet?.User?.RoleId),
                Amount = t.Amount,
                Description = t.Description,
                CreatedAt = t.CreatedAt
            }).ToList();

            // 3. Tab 2: Yêu cầu rút tiền
            var rawWithdrawals = await _context.WithdrawalRequests
                .Where(w => w.Status == 0)
                .Include(w => w.User).ThenInclude(u => u.Wallet)
                .ToListAsync();

            vm.PendingWithdrawals = rawWithdrawals.Select(w => new WithdrawalRequestViewModel
            {
                WithdrawalId = w.Id,
                UserId = w.UserId,
                UserFullName = w.User?.FullName ?? w.User?.Username ?? "N/A",
                UserRole = GetRoleLabel(w.User?.RoleId),
                Amount = w.Amount,
                CurrentWalletBalance = w.User?.Wallet?.Balance ?? 0,
                BankName = w.BankName,
                BankAccountNumber = w.BankAccountNumber,
                BankAccountName = w.BankAccountName,
                Note = w.Note,
                CreatedAt = w.CreatedAt
            }).ToList();

            // 4. Tab 3: Lịch sử giao dịch (200 GD gần nhất)
            var rawHistory = await _context.Transactions
                .Include(t => t.Wallet).ThenInclude(w => w.User)
                .OrderByDescending(t => t.CreatedAt).Take(200)
                .ToListAsync();

            vm.TransactionHistory = rawHistory.Select(t => new TransactionHistoryViewModel
            {
                TransactionId = t.Id,
                UserFullName = t.Wallet?.User?.FullName ?? t.Wallet?.User?.Username ?? "N/A",
                UserRole = GetRoleLabel(t.Wallet?.User?.RoleId),
                Amount = t.Amount,
                // Chỗ này gây lỗi lúc trước, nay chạy trên C# nên sẽ hết lỗi
                TypeLabel = (t.Type != null && TypeLabels.ContainsKey(t.Type)) ? TypeLabels[t.Type] : t.Type,
                Status = t.Status,
                Description = t.Description,
                CreatedAt = t.CreatedAt
            }).ToList();

            return View(vm);
        }

        // ==========================================
        // 2. DUYỆT NẠP TIỀN
        // ==========================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ApproveDeposit(int id)
        {
            var trans = await _context.Transactions.Include(t => t.Wallet).FirstOrDefaultAsync(t => t.Id == id);
            if (trans == null || trans.Status != 0) return RedirectToAction(nameof(Index));

            trans.Status = 1;
            trans.Wallet.Balance += trans.Amount;
            trans.Wallet.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();
            TempData["Success"] = "Đã duyệt nạp tiền thành công!";
            return RedirectToAction(nameof(Index));
        }

        // ==========================================
        // 3. XÁC NHẬN RÚT TIỀN (Đã chuyển khoản thật)
        // ==========================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ConfirmWithdrawal(int id, IFormFile? billImage, string? adminNote)
        {
            using var dbTx = await _context.Database.BeginTransactionAsync();
            try
            {
                var request = await _context.WithdrawalRequests
                    .Include(w => w.User).ThenInclude(u => u.Wallet)
                    .FirstOrDefaultAsync(w => w.Id == id);

                if (request == null || request.Status != 0) return RedirectToAction(nameof(Index));

                string? billUrl = null;
                if (billImage != null && billImage.Length > 0)
                {
                    var folder = Path.Combine(_env.WebRootPath, "uploads", "bills");
                    if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
                    var fileName = $"bill_withdraw_{id}_{DateTime.Now:ticks}{Path.GetExtension(billImage.FileName)}";
                    using (var stream = new FileStream(Path.Combine(folder, fileName), FileMode.Create))
                    {
                        await billImage.CopyToAsync(stream);
                    }
                    billUrl = "/uploads/bills/" + fileName;
                }

                var transaction = await _context.Transactions
                    .FirstOrDefaultAsync(t => t.WalletId == request.User.Wallet.Id && t.Type == "WITHDRAW" && t.Status == 0);

                if (transaction != null) transaction.Status = 1;

                request.Status = 1;
                request.AdminBillImageUrl = billUrl;
                request.AdminNote = adminNote;
                request.ProcessedAt = DateTime.Now;

                await _context.SaveChangesAsync();
                await dbTx.CommitAsync();
                TempData["Success"] = "Xác nhận rút tiền thành công!";
            }
            catch (Exception ex)
            {
                await dbTx.RollbackAsync();
                TempData["Error"] = "Lỗi: " + ex.Message;
            }
            return RedirectToAction(nameof(Index));
        }

        // ==========================================
        // 4. TỪ CHỐI RÚT TIỀN (Hoàn tiền)
        // ==========================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RejectWithdrawal(int id, string? reason)
        {
            using var dbTx = await _context.Database.BeginTransactionAsync();
            try
            {
                var request = await _context.WithdrawalRequests
                    .Include(w => w.User).ThenInclude(u => u.Wallet)
                    .FirstOrDefaultAsync(w => w.Id == id);

                if (request == null || request.Status != 0) return RedirectToAction(nameof(Index));

                var wallet = request.User.Wallet;
                wallet.Balance += request.Amount;
                wallet.UpdatedAt = DateTime.Now;

                var transaction = await _context.Transactions
                    .FirstOrDefaultAsync(t => t.WalletId == wallet.Id && t.Type == "WITHDRAW" && t.Status == 0);

                if (transaction != null)
                {
                    transaction.Status = 2;
                    transaction.Description += " (Bị từ chối)";
                }

                request.Status = 2;
                request.AdminNote = reason ?? "Không rõ lý do";
                request.ProcessedAt = DateTime.Now;

                await _context.SaveChangesAsync();
                await dbTx.CommitAsync();
                TempData["Success"] = "Đã từ chối và hoàn tiền.";
            }
            catch (Exception ex)
            {
                await dbTx.RollbackAsync();
                TempData["Error"] = "Lỗi: " + ex.Message;
            }
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RejectDeposit(int id, string? reason)
        {
            var trans = await _context.Transactions.FindAsync(id);
            if (trans == null || trans.Status != 0) return RedirectToAction(nameof(Index));
            trans.Status = 2;
            trans.Description += $" | Từ chối: {reason}";
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }
    }
}