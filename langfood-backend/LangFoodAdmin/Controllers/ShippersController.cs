using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.Models;
using LangFood.Shared.ViewModels;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodAdmin.Controllers
{
    public class ShippersController : Controller
    {
        private readonly LangFoodDbContext _context;

        public ShippersController(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var viewModel = new ShipperManagementViewModel
            {
                // 1. Lấy danh sách Shipper chờ duyệt (User có RoleId = 3 và chưa duyệt)
                PendingShippers = await _context.Users
                    .Where(u => u.RoleId == 3 && u.IsApproved == false)
                    .OrderByDescending(u => u.Id)
                    .ToListAsync(),

                // 2. Lấy danh sách Shipper đang hoạt động (Đã có trong bảng Shippers)
                ActiveShippers = await _context.Shippers
                    .Include(s => s.User)
                    .OrderByDescending(s => s.Id)
                    .ToListAsync()
            };

            return View(viewModel);
        }
    }
}
