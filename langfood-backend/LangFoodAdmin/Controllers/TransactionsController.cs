using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace LangFoodAdmin.Controllers
{
    public class TransactionsController : Controller
    {
        private readonly LangFoodDbContext _context;

        public TransactionsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. Hiển thị danh sách nạp tiền đang chờ duyệt
        public async Task<IActionResult> Index()
        {
            var pendingDeposits = await _context.Transactions
                .Where(t => t.Type == "DEPOSIT" && t.Status == 0)
                .Join(_context.Wallets, t => t.WalletId, w => w.Id, (t, w) => new { t, w })
                .Join(_context.Users, j => j.w.UserId, u => u.Id, (j, u) => new DepositViewModel
                {
                    TransactionId = j.t.Id,
                    UserFullName = u.FullName,
                    Amount = j.t.Amount,
                    Description = j.t.Description,
                    CreatedAt = j.t.CreatedAt,
                    OrderId = j.t.OrderId // Để biết đơn hàng nào đang được thanh toán
                })
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();

            return View(pendingDeposits);
        }

        // 2. Xử lý duyệt tiền
        [HttpPost]
        public async Task<IActionResult> Approve(int id)
        {
            // Sử dụng Transaction để đảm bảo an toàn dữ liệu
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

                    // B. QUAN TRỌNG: Nếu giao dịch này liên quan đến một Đơn hàng (Thanh toán QR)
                    // Trong file TransactionsController.cs, hàm Approve:
                    if (trans.OrderId.HasValue)
                    {
                        var order = await _context.Orders.FindAsync(trans.OrderId.Value);
                        if (order != null && order.Status == "PendingPayment")
                        {
                            // Đổi từ "Confirmed" sang "Paid" 
                            // Để báo cho hệ thống biết: Tiền đã vào túi Admin, giờ đợi Shop gật đầu.
                            order.Status = "Paid";
                        }
                    }

                    await _context.SaveChangesAsync();
                    await dbTransaction.CommitAsync();
                }
            }
            catch (Exception)
            {
                await dbTransaction.RollbackAsync();
            }

            return RedirectToAction(nameof(Index));
        }
    }

    // Class ViewModel để hiển thị dữ liệu ra trang Web
    public class DepositViewModel
    {
        public int TransactionId { get; set; }
        public string UserFullName { get; set; }
        public decimal Amount { get; set; }
        public string Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public int? OrderId { get; set; }
    }
}