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
    }
}