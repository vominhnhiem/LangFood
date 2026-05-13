using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.Models;
using LangFood.Shared.ViewModels;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodAdmin.Controllers
{
    public class RoleRequestsController : Controller
    {
        private readonly LangFoodDbContext _context;

        public RoleRequestsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. Trang Quản lý Cửa hàng
        public async Task<IActionResult> Index()
        {
            var viewModel = new ShopManagementViewModel
            {
                // Lấy yêu cầu mở quán chờ duyệt (RequestType = 1, Status = 0)
                PendingRequests = await _context.RoleRequests
                    .Include(r => r.User)
                    .Where(r => r.RequestType == 1 && r.Status == 0)
                    .OrderByDescending(r => r.CreatedAt)
                    .ToListAsync(),

                // Lấy danh sách cửa hàng đang hoạt động
                ActiveShops = await _context.Shops
                    .Include(s => s.User)
                    .OrderByDescending(s => s.Id)
                    .ToListAsync()
            };

            return View(viewModel);
        }

        // 2. Duyệt yêu cầu mở quán
        public async Task<IActionResult> Approve(int id)
        {
            var request = await _context.RoleRequests.Include(r => r.User).FirstOrDefaultAsync(r => r.Id == id);
            if (request != null)
            {
                request.Status = 1; // Duyệt
                
                // Tạo cửa hàng mới nếu chưa có
                var existingShop = await _context.Shops.FirstOrDefaultAsync(s => s.UserId == request.UserId);
                if (existingShop == null)
                {
                    var shop = new Shop
                    {
                        UserId = request.UserId,
                        Name = request.ShopName ?? "Cửa hàng mới",
                        Address = request.ShopAddress ?? "Chưa cập nhật",
                        IsActive = true,
                        IsOpen = true
                    };
                    _context.Shops.Add(shop);
                }

                await _context.SaveChangesAsync();
                TempData["Success"] = "Đã duyệt yêu cầu mở quán thành công!";
            }
            return RedirectToAction(nameof(Index));
        }

        // 3. Từ chối yêu cầu
        [HttpPost]
        public async Task<IActionResult> Reject(int id)
        {
            var request = await _context.RoleRequests.FindAsync(id);
            if (request != null)
            {
                request.Status = 2; // Từ chối
                await _context.SaveChangesAsync();
                TempData["Success"] = "Đã từ chối yêu cầu mở quán.";
            }
            return RedirectToAction(nameof(Index));
        }

        // 4. Khóa/Mở khóa cửa hàng (AJAX hoặc Link)
        public async Task<IActionResult> ToggleStatus(int id)
        {
            var shop = await _context.Shops.FindAsync(id);
            if (shop != null)
            {
                shop.IsActive = !shop.IsActive;
                await _context.SaveChangesAsync();
                TempData["Success"] = shop.IsActive ? "Đã mở khóa cửa hàng!" : "Đã khóa cửa hàng thành công!";
            }
            return RedirectToAction(nameof(Index));
        }
    }
}