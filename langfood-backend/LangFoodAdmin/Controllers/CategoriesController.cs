using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.Models;
using Microsoft.EntityFrameworkCore;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace LangFoodAdmin.Controllers
{
    public class CategoriesController : Controller
    {
        private readonly LangFoodDbContext _context;

        public CategoriesController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. Danh sách danh mục
        public async Task<IActionResult> Index()
        {
            var list = await _context.Categories.Where(c => !c.IsDeleted).OrderBy(c => c.Name).ToListAsync();
            return View(list);
        }

        [HttpGet]
        public IActionResult Create()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Create(Category category, IFormFile imageFile)
        {
            if (imageFile != null)
            {
                var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                
                // Lưu vào Backend để App và Admin cùng thấy (vì Admin đang link tới cổng Backend)
                var backendPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "LangFoodBackend", "wwwroot", "images", "categories");
                if (!Directory.Exists(backendPath)) Directory.CreateDirectory(backendPath);
                
                var filePath = Path.Combine(backendPath, fileName);
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await imageFile.CopyToAsync(stream);
                }
                category.ImageUrl = "images/categories/" + fileName;
            }

            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        // 3. Giao diện chỉnh sửa
        public async Task<IActionResult> Edit(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null) return NotFound();
            return View(category);
        }

        [HttpPost]
        public async Task<IActionResult> Edit(int id, Category category, IFormFile? imageFile)
        {
            if (id != category.Id) return NotFound();

            var existingCategory = await _context.Categories.FindAsync(id);
            if (existingCategory == null) return NotFound();

            if (ModelState.IsValid)
            {
                try
                {
                    existingCategory.Name = category.Name;

                    if (imageFile != null)
                    {
                        // Lưu ảnh mới vào Backend
                        var fileName = Guid.NewGuid().ToString() + Path.GetExtension(imageFile.FileName);
                        var backendPath = Path.Combine(Directory.GetCurrentDirectory(), "..", "LangFoodBackend", "wwwroot", "images", "categories");
                        if (!Directory.Exists(backendPath)) Directory.CreateDirectory(backendPath);
                        
                        var filePath = Path.Combine(backendPath, fileName);
                        using (var stream = new FileStream(filePath, FileMode.Create))
                        {
                            await imageFile.CopyToAsync(stream);
                        }
                        existingCategory.ImageUrl = "images/categories/" + fileName;
                    }

                    await _context.SaveChangesAsync();
                    TempData["Success"] = "Cập nhật danh mục thành công!";
                    return RedirectToAction(nameof(Index));
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!CategoryExists(category.Id)) return NotFound();
                    else throw;
                }
            }
            return View(category);
        }

        // 4. Xóa
        public async Task<IActionResult> Delete(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category != null)
            {
                category.IsDeleted = true;
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }

        private bool CategoryExists(int id)
        {
            return _context.Categories.Any(e => e.Id == id);
        }
    }
}