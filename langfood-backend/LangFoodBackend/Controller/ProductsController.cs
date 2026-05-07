using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
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
    public class ProductsController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public ProductsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. LẤY TẤT CẢ MÓN ĂN (Chỉ hiện món ĐÃ DUYỆT lên trang chủ App)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetProducts()
        {
            return await _context.Products
                .Include(p => p.Seller)
                .Where(p => p.IsAvailable && p.Status == 1) // CHỈ LẤY MÓN CÓ STATUS = 1 (APPROVED)
                .OrderByDescending(p => p.Id)
                .Select(p => new {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.Description,
                    p.ImageUrl,
                    p.IsAvailable,
                    p.Status, // Trả về để App biết trạng thái
                    p.SellerId,
                    p.CategoryId,
                    SellerName = p.Seller != null ? p.Seller.FullName : "Ẩn danh"
                })
                .ToListAsync();
        }

        // 2. LẤY CHI TIẾT MỘT MÓN ĂN
        [HttpGet("{id}")]
        public async Task<ActionResult<object>> GetProduct(int id)
        {
            var product = await _context.Products
                .Include(p => p.Seller)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (product == null)
            {
                return NotFound(new { message = "Không tìm thấy món này mày ơi!" });
            }

            return new
            {
                product.Id,
                product.Name,
                product.Price,
                product.Description,
                product.ImageUrl,
                product.IsAvailable,
                product.Status, // Trả về Status
                product.SellerId,
                product.CategoryId,
                SellerName = product.Seller?.FullName,
                SellerPhone = product.Seller?.PhoneNumber
            };
        }

        // 3. LẤY DANH SÁCH MÓN CỦA MỘT NGƯỜI BÁN (Để hiện trong trang Quản lý món ăn của Seller)
        // 3. LẤY DANH SÁCH MÓN CỦA MỘT NGƯỜI BÁN
        [HttpGet("seller/{sellerId}")]
        public async Task<ActionResult<IEnumerable<Product>>> GetProductsBySeller(string sellerId)
        {
            // Phải lấy TOÀN BỘ, không được có .Where(p => p.Status == 1) ở đây
            var products = await _context.Products
                .Where(p => p.SellerId == sellerId)
                .OrderByDescending(p => p.Id)
                .ToListAsync();

            return Ok(products);
        }

        // 4. ĐĂNG MÓN ĂN MỚI (Dạng JSON)
        [HttpPost]
        public async Task<ActionResult<Product>> PostProduct(Product product)
        {
            var sellerExists = await _context.Users.AnyAsync(u => u.Id == product.SellerId);
            if (!sellerExists)
            {
                return BadRequest(new { message = "Lỗi: Người bán không tồn tại!" });
            }

            product.IsAvailable = true;
            product.Status = 0; // MẶC ĐỊNH LÀ CHỜ DUYỆT (PENDING)

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
        }

        // 4b. ĐĂNG MÓN ĂN KÈM FILE ẢNH (Dành cho chức năng App Android)
        [HttpPost("upload")]
        public async Task<ActionResult<Product>> PostProductWithImage(
            [FromForm] string name,
            [FromForm] decimal price,
            [FromForm] string description,
            [FromForm] string sellerId,
            [FromForm] int categoryId,
            IFormFile image)
        {
            // Kiểm tra Seller có tồn tại không
            var sellerExists = await _context.Users.AnyAsync(u => u.Id == sellerId);
            if (!sellerExists) return BadRequest(new { message = "Người bán không tồn tại!" });

            // Kiểm tra Category có tồn tại không
            var categoryExists = await _context.Categories.AnyAsync(c => c.Id == categoryId);
            if (!categoryExists) return BadRequest(new { message = "Danh mục không tồn tại!" });

            string imageUrl = "images/products/default_food.png";

            if (image != null && image.Length > 0)
            {
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "products");
                if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

                var fileName = Guid.NewGuid().ToString() + Path.GetExtension(image.FileName);
                var filePath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await image.CopyToAsync(stream);
                }
                imageUrl = "images/products/" + fileName;
            }

            var product = new Product
            {
                Name = name,
                Price = price,
                Description = description,
                SellerId = sellerId,
                CategoryId = categoryId,
                ImageUrl = imageUrl,
                IsAvailable = true,
                Status = 0 // MẶC ĐỊNH LÀ CHỜ DUYỆT KHI MỚI UP
            };

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            return Ok(product);
        }

        // 5. CẬP NHẬT MÓN ĂN
        [HttpPut("{id}")]
        public async Task<IActionResult> PutProduct(int id, Product product)
        {
            if (id != product.Id) return BadRequest();

            // Khi Seller sửa món, có thể giữ nguyên Status hoặc reset về 0 tùy mày muốn
            product.Status = 0;
            // Ở đây tao giữ nguyên Status cũ để tránh việc cứ sửa là phải duyệt lại
            _context.Entry(product).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ProductExists(id)) return NotFound();
                else throw;
            }

            return Ok(new { message = "Cập nhật thành công!" });
        }

        // 6. XÓA MÓN ĂN
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();

            _context.Products.Remove(product);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa món ăn." });
        }

        private bool ProductExists(int id)
        {
            return _context.Products.Any(e => e.Id == id);
        }
    }
}