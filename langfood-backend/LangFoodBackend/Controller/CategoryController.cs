using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFood.Shared; // Để nhận diện LangFoodDbContext
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodBackend.Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class CategoriesController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public CategoriesController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. LẤY TẤT CẢ THỂ LOẠI (Dùng cho App và Admin)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories()
        {
            return await _context.Categories.OrderBy(c => c.Name).ToListAsync();
        }

        // 2. LẤY CHI TIẾT MỘT THỂ LOẠI
        [HttpGet("{id}")]
        public async Task<ActionResult<Category>> GetCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);

            if (category == null)
            {
                return NotFound(new { message = "Không tìm thấy thể loại này" });
            }

            return category;
        }

        // 3. THÊM MỚI DANH MỤC KÈM FILE ẢNH (Dùng cho Web Admin)
        [HttpPost("upload")]
        public async Task<ActionResult<Category>> PostCategoryWithImage(
            [FromForm] string name,
            IFormFile image)
        {
            if (string.IsNullOrEmpty(name))
            {
                return BadRequest(new { message = "Tên danh mục không được để trống!" });
            }

            string imageUrl = "images/categories/default.png";

            if (image != null && image.Length > 0)
            {
                // Đường dẫn thư mục lưu ảnh: wwwroot/images/categories
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "categories");
                if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

                // Tạo tên file duy nhất bằng GUID
                var fileName = Guid.NewGuid().ToString() + Path.GetExtension(image.FileName);
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await image.CopyToAsync(stream);
                }

                // Lưu đường dẫn tương đối vào database
                imageUrl = "images/categories/" + fileName;
            }

            var category = new Category { Name = name, ImageUrl = imageUrl };
            _context.Categories.Add(category);
            await _context.SaveChangesAsync();

            return Ok(category);
        }

        // 4. CẬP NHẬT THỂ LOẠI (JSON chuẩn)
        [HttpPut("{id}")]
        public async Task<IActionResult> PutCategory(int id, Category category)
        {
            if (id != category.Id)
            {
                return BadRequest();
            }

            _context.Entry(category).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!CategoryExists(id)) return NotFound();
                else throw;
            }

            return Ok(new { message = "Cập nhật thành công!" });
        }

        // 5. XÓA THỂ LOẠI
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null) return NotFound();

            // 1. Đánh dấu xóa Danh mục
            category.IsDeleted = true;

            // 2. Đánh dấu xóa luôn toàn bộ Sản phẩm thuộc danh mục này
            var products = _context.Products.Where(p => p.CategoryId == id);
            foreach (var p in products)
            {
                p.IsDeleted = true;
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xóa (ẩn) danh mục thành công!" });
        }

        private bool CategoryExists(int id)
        {
            return _context.Categories.Any(e => e.Id == id);
        }
    }
}