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

namespace LangFoodAdmin.Controllers
{
    /// <summary>
    /// Finance Controller – Quản lý 3 luồng tiền trong hệ thống:
    ///   1. Nạp tiền  (DEPOSIT)   : Admin duyệt, cộng tiền ảo vào ví người dùng.
    ///   2. Rút tiền  (WITHDRAWAL): Admin chuyển khoản thật, upload bill, trừ ví ảo.
    ///   3. Lịch sử   (HISTORY)  : Xem toàn bộ biến động số dư.
    /// Mọi thao tác tài chính đều bọc trong IDbContextTransaction để đảm bảo ACID.
    /// </summary>
    public class FinanceController : Controller
    {
        private readonly LangFoodDbContext _context;
        private readonly IWebHostEnvironment _env;

        // Mapping loại giao dịch -> nhãn tiếng Việt
        private static readonly System.Collections.Generic.Dictionary<string, string> TypeLabels = new()
        {
            ["DEPOSIT"]       = "Nạp tiền vào ví",
            ["WITHDRAW"]      = "Rút tiền ra",
            ["ORDER_PAYMENT"] = "Thanh toán đơn hàng",
            ["ORDER_DEPOSIT"] = "Đặt cọc giao hàng",
            ["RECEIVE_REWARD"] = "Nhận thưởng / Hoàn cọc",
            ["REFUND"]        = "Hoàn tiền",
            ["FEE"]           = "Phí hệ thống",
            ["ADMIN_FEE"]     = "Hoa hồng Admin",
        };

        // Mapping RoleId -> tên vai trò hiển thị
        private static string GetRoleLabel(int roleId) => roleId switch
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
            _env     = env;
        }

        // ================================================================
        //  GET /Finance  –  Trang tổng quan Finance
        // ================================================================
        public async Task<IActionResult> Index()
        {
            var vm = new FinanceDashboardViewModel();

            // --- 1. Dashboard Cards ---
            vm.TotalSystemBalance = await _context.Wallets.SumAsync(w => w.Balance);

            vm.TotalAdminRevenue = await _context.Transactions
                .Where(t => (t.Type == "FEE" || t.Type == "ADMIN_FEE") && t.Status == 1)
                .SumAsync(t => t.Amount);

            vm.PendingDepositCount = await _context.Transactions
                .Where(t => t.Type == "DEPOSIT" && t.Status == 0)
                .CountAsync();

            vm.PendingWithdrawalCount = await _context.WithdrawalRequests
                .Where(w => w.Status == 0)
                .CountAsync();

            // --- 2. Tab 1: Yêu cầu nạp tiền đang chờ duyệt ---
            var rawDeposits = await _context.Transactions
                .AsNoTracking()
                .Where(t => t.Type == "DEPOSIT" && t.Status == 0)
                .Include(t => t.Wallet)
                    .ThenInclude(w => w!.User)
                .OrderByDescending(t => t.CreatedAt)
                .Select(t => new
                {
                    TransactionId = t.Id,
                    UserId        = t.Wallet!.UserId,
                    UserFullName  = t.Wallet.User != null ? (t.Wallet.User.FullName ?? t.Wallet.User.Username) : "N/A",
                    RoleId        = t.Wallet.User != null ? t.Wallet.User.RoleId : 0,
                    Amount        = t.Amount,
                    Description   = t.Description,
                    CreatedAt     = t.CreatedAt,
                    OrderId       = t.OrderId
                })
                .ToListAsync();

            vm.PendingDeposits = rawDeposits.Select(t => new DepositRequestViewModel
            {
                TransactionId = t.TransactionId,
                UserId        = t.UserId,
                UserFullName  = t.UserFullName,
                UserRole      = GetRoleLabel(t.RoleId),
                Amount        = t.Amount,
                Description   = t.Description ?? "",
                BillImageUrl  = null,
                CreatedAt     = t.CreatedAt,
                OrderId       = t.OrderId
            }).ToList();

            // --- 3. Tab 2: Yêu cầu rút tiền đang chờ xử lý ---
            var rawWithdrawals = await _context.WithdrawalRequests
                .AsNoTracking()
                .Where(w => w.Status == 0)
                .Include(w => w.User)
                    .ThenInclude(u => u!.Wallet)
                .OrderByDescending(w => w.CreatedAt)
                .Select(w => new
                {
                    WithdrawalId         = w.Id,
                    UserId               = w.UserId,
                    UserFullName         = w.User != null ? (w.User.FullName ?? w.User.Username) : "N/A",
                    RoleId               = w.User != null ? w.User.RoleId : 0,
                    Amount               = w.Amount,
                    CurrentWalletBalance = w.User != null && w.User.Wallet != null ? w.User.Wallet.Balance : 0,
                    BankName             = w.BankName,
                    BankAccountNumber    = w.BankAccountNumber,
                    BankAccountName      = w.BankAccountName,
                    Note                 = w.Note,
                    CreatedAt            = w.CreatedAt
                })
                .ToListAsync();

            vm.PendingWithdrawals = rawWithdrawals.Select(w => new WithdrawalRequestViewModel
            {
                WithdrawalId         = w.WithdrawalId,
                UserId               = w.UserId,
                UserFullName         = w.UserFullName,
                UserRole             = GetRoleLabel(w.RoleId),
                Amount               = w.Amount,
                CurrentWalletBalance = w.CurrentWalletBalance,
                BankName             = w.BankName,
                BankAccountNumber    = w.BankAccountNumber,
                BankAccountName      = w.BankAccountName,
                Note                 = w.Note,
                CreatedAt            = w.CreatedAt
            }).ToList();

            // --- 4. Tab 3: Lịch sử biến động (100 giao dịch gần nhất) ---
            var rawHistory = await _context.Transactions
                .AsNoTracking()
                .Include(t => t.Wallet)
                    .ThenInclude(w => w!.User)
                .OrderByDescending(t => t.CreatedAt)
                .Take(200)
                .Select(t => new
                {
                    TransactionId = t.Id,
                    UserFullName  = t.Wallet != null && t.Wallet.User != null
                                    ? (t.Wallet.User.FullName ?? t.Wallet.User.Username)
                                    : "N/A",
                    RoleId        = t.Wallet != null && t.Wallet.User != null ? t.Wallet.User.RoleId : 0,
                    Amount        = t.Amount,
                    Type          = t.Type,
                    Description   = t.Description,
                    Status        = t.Status,
                    CreatedAt     = t.CreatedAt,
                    OrderId       = t.OrderId
                })
                .ToListAsync();

            vm.TransactionHistory = rawHistory.Select(t => new TransactionHistoryViewModel
            {
                TransactionId = t.TransactionId,
                UserFullName  = t.UserFullName,
                UserRole      = GetRoleLabel(t.RoleId),
                Amount        = t.Amount,
                Type          = t.Type ?? "",
                TypeLabel     = t.Type != null && TypeLabels.ContainsKey(t.Type)
                                ? TypeLabels[t.Type]
                                : (t.Type ?? "Khác"),
                Description   = t.Description ?? "",
                Status        = t.Status,
                CreatedAt     = t.CreatedAt,
                OrderId       = t.OrderId
            }).ToList();

            return View(vm);
        }

        // ================================================================
        //  POST /Finance/ApproveDeposit/{id}
        //  Duyệt nạp tiền: Cộng tiền vào ví + đổi trạng thái Transaction.
        //  Dùng IDbContextTransaction để đảm bảo ACID.
        // ================================================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ApproveDeposit(int id)
        {
            using var dbTx = await _context.Database.BeginTransactionAsync();
            try
            {
                var transaction = await _context.Transactions
                    .Include(t => t.Wallet)
                    .FirstOrDefaultAsync(t => t.Id == id);

                if (transaction == null)
                {
                    TempData["Error"] = $"Không tìm thấy giao dịch #{id}.";
                    return RedirectToAction(nameof(Index));
                }

                if (transaction.Status != 0)
                {
                    TempData["Warning"] = "Giao dịch này đã được xử lý trước đó.";
                    return RedirectToAction(nameof(Index));
                }

                if (transaction.Wallet == null)
                {
                    TempData["Error"] = "Không tìm thấy ví liên kết với giao dịch này.";
                    return RedirectToAction(nameof(Index));
                }

                // BƯỚC 1: Cộng tiền vào ví người dùng
                transaction.Wallet.Balance  += transaction.Amount;
                transaction.Wallet.UpdatedAt = DateTime.Now;

                // BƯỚC 2: Đánh dấu giao dịch thành công
                transaction.Status = 1; // Success

                // BƯỚC 3 (tùy chọn): Nếu giao dịch liên quan đến đơn hàng QR → chuyển trạng thái đơn
                if (transaction.OrderId.HasValue)
                {
                    var order = await _context.Orders.FindAsync(transaction.OrderId.Value);
                    if (order != null && order.Status == "PendingPayment")
                    {
                        order.Status = "Paid";
                    }
                }

                await _context.SaveChangesAsync();
                await dbTx.CommitAsync(); // ✅ Commit toàn bộ khi mọi bước đều thành công

                TempData["Success"] = $"✅ Đã duyệt nạp {transaction.Amount:N0}đ vào ví thành công!";
            }
            catch (Exception ex)
            {
                await dbTx.RollbackAsync(); // ❌ Rollback nếu bất kỳ bước nào lỗi
                TempData["Error"] = $"Lỗi hệ thống khi duyệt nạp tiền: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // ================================================================
        //  POST /Finance/RejectDeposit/{id}
        //  Từ chối nạp tiền.
        // ================================================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RejectDeposit(int id, string? reason)
        {
            var transaction = await _context.Transactions.FindAsync(id);

            if (transaction == null || transaction.Status != 0)
            {
                TempData["Warning"] = "Giao dịch không tồn tại hoặc đã được xử lý.";
                return RedirectToAction(nameof(Index));
            }

            transaction.Status      = 2; // Rejected
            transaction.Description = (transaction.Description ?? "") + $" | Từ chối: {reason ?? "Không rõ lý do"}";

            await _context.SaveChangesAsync();
            TempData["Success"] = "Đã từ chối yêu cầu nạp tiền.";
            return RedirectToAction(nameof(Index));
        }

        // ================================================================
        //  POST /Finance/ConfirmWithdrawal/{id}
        //  Xác nhận đã chuyển khoản thật:
        //   1. Trừ tiền ảo khỏi ví người dùng
        //   2. Ghi lịch sử giao dịch WITHDRAW
        //   3. Lưu URL ảnh bill Admin upload
        //  Dùng IDbContextTransaction để đảm bảo ACID.
        // ================================================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ConfirmWithdrawal(int id, IFormFile? billImage, string? adminNote)
        {
            using var dbTx = await _context.Database.BeginTransactionAsync();
            try
            {
                var withdrawalRequest = await _context.WithdrawalRequests
                    .Include(w => w.User)
                        .ThenInclude(u => u!.Wallet)
                    .FirstOrDefaultAsync(w => w.Id == id);

                if (withdrawalRequest == null)
                {
                    TempData["Error"] = $"Không tìm thấy lệnh rút #{id}.";
                    return RedirectToAction(nameof(Index));
                }

                if (withdrawalRequest.Status != 0)
                {
                    TempData["Warning"] = "Lệnh rút này đã được xử lý rồi.";
                    return RedirectToAction(nameof(Index));
                }

                var wallet = withdrawalRequest.User?.Wallet;
                if (wallet == null)
                {
                    TempData["Error"] = "Không tìm thấy ví của người dùng.";
                    return RedirectToAction(nameof(Index));
                }

                if (wallet.Balance < withdrawalRequest.Amount)
                {
                    TempData["Error"] = $"Số dư ví ({wallet.Balance:N0}đ) không đủ để rút {withdrawalRequest.Amount:N0}đ.";
                    return RedirectToAction(nameof(Index));
                }

                // BƯỚC 1: Xử lý upload ảnh bill (nếu có)
                string? billImageUrl = null;
                if (billImage != null && billImage.Length > 0)
                {
                    var uploadsFolder = Path.Combine(_env.WebRootPath, "uploads", "bills");
                    Directory.CreateDirectory(uploadsFolder);

                    var fileName  = $"withdrawal_{id}_{DateTime.Now:yyyyMMddHHmmss}{Path.GetExtension(billImage.FileName)}";
                    var filePath  = Path.Combine(uploadsFolder, fileName);

                    using var stream = new FileStream(filePath, FileMode.Create);
                    await billImage.CopyToAsync(stream);

                    billImageUrl = $"/uploads/bills/{fileName}";
                }

                // BƯỚC 2: Trừ tiền ảo khỏi ví người dùng
                wallet.Balance  -= withdrawalRequest.Amount;
                wallet.UpdatedAt = DateTime.Now;

                // BƯỚC 3: Ghi lịch sử giao dịch WITHDRAW (Amount âm = trừ tiền)
                _context.Transactions.Add(new Transaction
                {
                    WalletId    = wallet.Id,
                    Amount      = -withdrawalRequest.Amount,
                    Type        = "WITHDRAW",
                    Description = $"Rút tiền thật - Ngân hàng: {withdrawalRequest.BankName} - STK: {withdrawalRequest.BankAccountNumber}",
                    Status      = 1,
                    CreatedAt   = DateTime.Now
                });

                // BƯỚC 4: Cập nhật trạng thái lệnh rút
                withdrawalRequest.Status          = 1; // Đã hoàn thành
                withdrawalRequest.AdminBillImageUrl = billImageUrl;
                withdrawalRequest.AdminNote        = adminNote;
                withdrawalRequest.ProcessedAt      = DateTime.Now;

                await _context.SaveChangesAsync();
                await dbTx.CommitAsync(); // ✅ Commit toàn bộ

                TempData["Success"] = $"✅ Đã xác nhận chuyển khoản {withdrawalRequest.Amount:N0}đ cho {withdrawalRequest.User?.FullName}!";
            }
            catch (Exception ex)
            {
                await dbTx.RollbackAsync(); // ❌ Rollback nếu lỗi
                TempData["Error"] = $"Lỗi hệ thống khi xử lý rút tiền: {ex.Message}";
            }

            return RedirectToAction(nameof(Index));
        }

        // ================================================================
        //  POST /Finance/RejectWithdrawal/{id}
        //  Từ chối lệnh rút tiền (không trừ ví, chỉ đổi trạng thái).
        // ================================================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> RejectWithdrawal(int id, string? reason)
        {
            var withdrawalRequest = await _context.WithdrawalRequests.FindAsync(id);

            if (withdrawalRequest == null || withdrawalRequest.Status != 0)
            {
                TempData["Warning"] = "Lệnh rút không tồn tại hoặc đã được xử lý.";
                return RedirectToAction(nameof(Index));
            }

            withdrawalRequest.Status      = 2; // Từ chối
            withdrawalRequest.AdminNote   = reason ?? "Không rõ lý do";
            withdrawalRequest.ProcessedAt = DateTime.Now;

            await _context.SaveChangesAsync();
            TempData["Success"] = "Đã từ chối lệnh rút tiền.";
            return RedirectToAction(nameof(Index));
        }

        // ================================================================
        //  GET /Finance/GetBillImage/{transactionId}
        //  Lấy URL ảnh bill (proof) của người dùng gửi khi nạp tiền.
        //  Trả về JSON để Modal hiển thị.
        // ================================================================
        [HttpGet]
        public async Task<IActionResult> GetBillImage(int transactionId)
        {
            var transaction = await _context.Transactions.FindAsync(transactionId);
            if (transaction == null) return NotFound();

            // Hiện tại Description chứa mã GD / nội dung chuyển khoản
            // Khi tích hợp upload ảnh từ app mobile, BillImageUrl sẽ được lưu trong Transaction
            return Json(new
            {
                transactionId,
                description  = transaction.Description,
                amount       = transaction.Amount,
                billImageUrl = (string?)null // TODO: Thêm field BillImageUrl vào Transaction model
            });
        }
    }
}
