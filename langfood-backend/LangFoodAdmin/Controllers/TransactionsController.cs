using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System.Threading.Tasks;
using System.Linq;
using System;
using System.Collections.Generic;

namespace LangFoodAdmin.Controllers
{
    public class TransactionsController : Controller
    {
        private readonly LangFoodDbContext _context;

        public TransactionsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // Hàm helper để lấy nhãn vai trò (Sửa lại: 1 là Sinh viên, 4 là Super Admin)
        private static string GetRoleLabel(int? roleId) => roleId switch
        {
            1 => "Sinh viên",
            2 => "Quán ăn",
            3 => "Shipper",
            4 => "Super Admin",
            _ => "Người dùng"
        };

        // 1. Hiển thị danh sách nạp tiền đang chờ duyệt
        public async Task<IActionResult> Index()
        {
            var pendingDeposits = await _context.Transactions
                .Where(t => t.Type == "DEPOSIT" && t.Status == 0)
                .Join(_context.Wallets, t => t.WalletId, w => w.Id, (t, w) => new { t, w })
                .Join(_context.Users, j => j.w.UserId, u => u.Id, (j, u) => new DepositViewModel
                {
                    TransactionId = j.t.Id,
                    UserFullName = u.FullName ?? u.Username,
                    UserRole = GetRoleLabel(u.RoleId), // Thêm logic lấy vai trò ở đây
                    Amount = j.t.Amount,
                    Description = j.t.Description,
                    CreatedAt = j.t.CreatedAt,
                    OrderId = j.t.OrderId
                })
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();

            return View(pendingDeposits);
        }

        // 2. Xử lý duyệt tiền
        [HttpPost]
        public async Task<IActionResult> Approve(int id)
        {
            using var dbTransaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var trans = await _context.Transactions.FindAsync(id);
                if (trans == null || trans.Status != 0)
                    return RedirectToAction(nameof(Index));

                var wallet = await _context.Wallets.FindAsync(trans.WalletId);
                if (wallet != null)
                {
                    // A. Cập nhật trạng thái giao dịch và cộng tiền vào ví
                    trans.Status = 1; // Thành công
                    wallet.Balance += trans.Amount;
                    wallet.UpdatedAt = DateTime.Now;

                    // B. Cập nhật trạng thái Đơn hàng
                    if (trans.OrderId.HasValue)
                    {
                        var order = await _context.Orders.FindAsync(trans.OrderId.Value);
                        if (order != null && order.Status == "PendingPayment")
                        {
                            // Đổi sang "Pending" để Quán thấy đơn và Người mua thấy "Chờ xác nhận"
                            // Không nên để "Paid" vì App Android của Quán đang tìm trạng thái "Pending"
                            order.Status = "Pending";
                        }
                    }

                    await _context.SaveChangesAsync();
                    await dbTransaction.CommitAsync();
                    TempData["Success"] = "Duyệt nạp tiền thành công!";
                }
            }
            catch (Exception ex)
            {
                await dbTransaction.RollbackAsync();
                TempData["Error"] = "Lỗi xử lý: " + ex.Message;
            }

            return RedirectToAction(nameof(Index));
        }
    }

    // Class ViewModel để hiển thị dữ liệu ra trang Web
    public class DepositViewModel
    {
        public int TransactionId { get; set; }
        public string UserFullName { get; set; }
        public string UserRole { get; set; } // Thuộc tính hiển thị vai trò
        public decimal Amount { get; set; }
        public string Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? OrderId { get; set; }
    }
}