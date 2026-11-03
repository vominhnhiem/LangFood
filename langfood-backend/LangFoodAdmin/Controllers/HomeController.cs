using System.Diagnostics;
using LangFoodAdmin.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;

namespace LangFoodAdmin.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly LangFoodDbContext _context;

        public HomeController(ILogger<HomeController> logger, LangFoodDbContext context)
        {
            _logger = logger;
            _context = context;
        }

        public async Task<IActionResult> Index()
        {


            var pendingShipperCount = await _context.RoleRequests.CountAsync(r => r.RequestType == 2 && r.Status == 0);
            var pendingWithdrawalCount = await _context.WithdrawalRequests.CountAsync(w => w.Status == 0);
            var pendingShopCount = await _context.RoleRequests.CountAsync(r => r.RequestType != 2 && r.Status == 0);
            var pendingAdminCount = await _context.Users.CountAsync(u => u.RoleId == 0 && !u.IsApproved);

            // ViewBag cho _Layout sidebar badges (toàn bộ trang đều dùng được)
            ViewBag.PendingShipperCount = pendingShipperCount;
            ViewBag.PendingWithdrawalCount = pendingWithdrawalCount;
            ViewBag.PendingShopCount = pendingShopCount;
            ViewBag.PendingAdminCount = pendingAdminCount;
            ViewBag.TotalPendingCount = pendingShipperCount + pendingWithdrawalCount + pendingShopCount + pendingAdminCount;

            var viewModel = new DashboardViewModel
            {
                PendingWithdrawalCount = pendingWithdrawalCount,
                PendingShipperCount = pendingShipperCount,
                PendingShopCount = pendingShopCount,
                PendingAdminCount = pendingAdminCount,
                LatestLogs = await _context.SystemLogs
                    .OrderByDescending(l => l.CreatedAt)
                    .Take(5)
                    .ToListAsync()
            };
            return View(viewModel);
        }

        [AllowAnonymous]
        public IActionResult Privacy()
        {
            return View();
        }

        [AllowAnonymous]
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }
    }
}
