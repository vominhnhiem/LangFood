using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFoodAdmin.Models;
using System.Threading.Tasks;

namespace LangFoodAdmin.Controllers
{
    public class DashboardController : Controller
    {
        private readonly LangFoodDbContext _context;

        public DashboardController(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {

            // Dashboard này có 2 vai trò Super Admin và Admin
            var now = DateTime.Now;
            var startOfMonth = new DateTime(now.Year, now.Month, 1);
            var startOfNextMonth = startOfMonth.AddMonths(1);

            var viewModel = new DashboardViewModel
            {
                PendingWithdrawalCount = await _context.WithdrawalRequests.CountAsync(w => w.Status == 0),
                PendingShipperCount = await _context.RoleRequests.CountAsync(r => r.RequestType == 2 && r.Status == 0),
                LatestLogs = await _context.SystemLogs
                    .OrderByDescending(l => l.CreatedAt)
                    .Take(5)
                    .ToListAsync(),
                TotalOrdersThisMonth = await _context.Orders
                    .CountAsync(o => o.CreatedAt >= startOfMonth && o.CreatedAt < startOfNextMonth),
                TotalUsers = await _context.Users.CountAsync(),
                LatestOrders = await _context.Orders
                    .Include(o => o.Shop)
                    .Include(o => o.Buyer)
                    .OrderByDescending(o => o.CreatedAt)
                    .Take(5)
                    .ToListAsync()
            };

            return View(viewModel);
        }
    }
}
