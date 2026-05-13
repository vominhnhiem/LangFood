using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.Models;
using LangFood.Shared.ViewModels;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace LangFoodAdmin.Controllers
{
    public class ProductsController : Controller
    {
        private readonly LangFoodDbContext _context;

        public ProductsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // Trang danh sách món
        public async Task<IActionResult> Index()
        {
            var viewModel = new ProductManagementViewModel
            {
                // 1. Lấy món ăn chờ duyệt (Status = 0)
                PendingProducts = await _context.Products
                    .Include(p => p.Shop)
                    .Include(p => p.Category)
                    .Where(p => p.Status == 0)
                    .OrderByDescending(p => p.Id)
                    .ToListAsync(),

                // 2. Lấy món ăn đang hoạt động (Status = 1)
                ActiveProducts = await _context.Products
                    .Include(p => p.Shop)
                    .Include(p => p.Category)
                    .Where(p => p.Status == 1)
                    .OrderByDescending(p => p.Id)
                    .ToListAsync(),

                // 3. Lấy dữ liệu cho bộ lọc
                Categories = await _context.Categories.OrderBy(c => c.Name).ToListAsync(),
                Shops = await _context.Shops.OrderBy(s => s.Name).ToListAsync()
            };

            return View(viewModel);
        }

        // Action Duyệt món
        public async Task<IActionResult> Approve(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product != null)
            {
                product.Status = 1; // Duyệt
                await _context.SaveChangesAsync();
                TempData["Msg"] = "Đã duyệt món ăn thành công!";
            }
            return RedirectToAction(nameof(Index));
        }

        // Action Từ chối món
        [HttpPost]
        public async Task<IActionResult> Reject(int id, string reason)
        {
            var product = await _context.Products.FindAsync(id);
            if (product != null)
            {
                product.Status = -1; // Từ chối/Bị khóa
                await _context.SaveChangesAsync();
                TempData["Msg"] = "Đã từ chối món ăn!";
            }
            return RedirectToAction(nameof(Index));
        }

        // API lấy chi tiết món ăn (AJAX)
        [HttpGet]
        public async Task<IActionResult> GetDetails(int id)
        {
            var product = await _context.Products
                .Include(p => p.Shop)
                .Include(p => p.Category)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (product == null) 
                return Json(new { success = false, message = "Không tìm thấy món ăn" });

            return Json(new
            {
                success = true,
                data = new
                {
                    id = product.Id,
                    name = product.Name,
                    price = product.Price,
                    description = product.Description ?? "Không có mô tả cho món ăn này.",
                    imageUrl = product.ImageUrl,
                    shopName = product.Shop?.Name ?? "N/A",
                    categoryName = product.Category?.Name ?? "N/A"
                }
            });
        }

        // Action Khóa/Mở khóa món ăn (AJAX)
        [HttpPost]
        public async Task<IActionResult> ToggleStatus(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) 
                return Json(new { success = false, message = "Không tìm thấy món ăn" });

            // Đảo ngược trạng thái hiển thị
            product.IsAvailable = !product.IsAvailable;
            await _context.SaveChangesAsync();

            return Json(new { 
                success = true, 
                message = product.IsAvailable ? "Đã mở khóa món ăn!" : "Đã ẩn món ăn thành công!", 
                isAvailable = product.IsAvailable 
            });
        }
    }
}