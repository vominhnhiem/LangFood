using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.Models;
using LangFood.Shared.ViewModels;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.SignalR;
using LangFoodAdmin.Hubs;
using System;

namespace LangFoodAdmin.Controllers
{
    public class RoleRequestsController : Controller
    {
        private readonly LangFoodDbContext _context;
        private readonly IHubContext<OrderHub> _hubContext;

        public RoleRequestsController(LangFoodDbContext context, IHubContext<OrderHub> hubContext)
        {
            _context = context;
            _hubContext = hubContext;
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
            // Include thêm User để có thể cập nhật trạng thái phê duyệt của tài khoản
            var request = await _context.RoleRequests.Include(r => r.User).FirstOrDefaultAsync(r => r.Id == id);

            if (request != null)
            {
                // Bước 1: Cập nhật trạng thái yêu cầu thành "Đã duyệt"
                request.Status = 1;

                // Bước 2: QUAN TRỌNG - Kích hoạt tài khoản người dùng
                if (request.User != null)
                {
                    request.User.IsApproved = true;
                }

                // Bước 3: Tạo cửa hàng mới nếu chưa có
                var existingShop = await _context.Shops.FirstOrDefaultAsync(s => s.UserId == request.UserId);
                Shop? shop = null;
                if (existingShop == null)
                {
                    shop = new Shop
                    {
                        UserId = request.UserId,
                        Name = request.ShopName ?? "Cửa hàng mới",
                        Address = request.ShopAddress ?? "Chưa cập nhật",
                        IsActive = true,
                        IsOpen = true
                    };
                    _context.Shops.Add(shop);
                }

                // Lưu tất cả thay đổi vào Database
                await _context.SaveChangesAsync();

                // Tạo SystemLog lưu vào Database
                var shopName = shop?.Name ?? existingShop?.Name ?? "Cửa hàng mới";
                var log = new SystemLog
                {
                    Content = $"Quán {shopName} vừa gia nhập hệ thống",
                    LogType = LogType.Shop,
                    CreatedAt = DateTime.Now
                };
                _context.SystemLogs.Add(log);
                await _context.SaveChangesAsync();

                // Phát tín hiệu SignalR qua Hub
                await _hubContext.Clients.All.SendAsync("ReceiveNewLog", new { content = log.Content, type = "Shop", time = "Vừa xong" });

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

        // 4. Khóa/Mở khóa cửa hàng
        public async Task<IActionResult> ToggleStatus(int id)
        {
            var shop = await _context.Shops.Include(s => s.User).FirstOrDefaultAsync(s => s.Id == id);
            if (shop != null)
            {
                shop.IsActive = !shop.IsActive;

                // Đồng bộ trạng thái phê duyệt của User theo trạng thái khóa của cửa hàng
                if (shop.User != null)
                {
                    shop.User.IsApproved = shop.IsActive;
                }

                await _context.SaveChangesAsync();
                TempData["Success"] = shop.IsActive ? "Đã mở khóa cửa hàng!" : "Đã khóa cửa hàng thành công!";
            }
            return RedirectToAction(nameof(Index));
        }
    }
}
