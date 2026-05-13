using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
namespace LangFoodAdmin.Controllers
{
    public class TransactionsController : Controller
    {
        private readonly LangFoodDbContext _context;

        public TransactionsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // Hiển thị danh sách nạp tiền đang chờ
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
                    CreatedAt = j.t.CreatedAt
                })
                .ToListAsync();

            return View(pendingDeposits);
        }

        [HttpPost]
        public async Task<IActionResult> Approve(int id)
        {
            var trans = await _context.Transactions.FindAsync(id);
            if (trans != null)
            {
                var wallet = await _context.Wallets.FindAsync(trans.WalletId);
                if (wallet != null)
                {
                    trans.Status = 1;
                    wallet.Balance += trans.Amount;
                    await _context.SaveChangesAsync();
                }
            }
            return RedirectToAction(nameof(Index));
        }
    }

    // Class tạm để hiển thị dữ liệu ra View
    public class DepositViewModel
    {
        public int TransactionId { get; set; }
        public string UserFullName { get; set; }
        public decimal Amount { get; set; }
        public string Description { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}