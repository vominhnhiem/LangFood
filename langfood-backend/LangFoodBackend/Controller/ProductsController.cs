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

        // 1. LẤY TẤT CẢ MÓN ĂN (Hiện lên trang chủ App - Chỉ hiện món đã duyệt Status = 1)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetProducts()
        {
            return await _context.Products
                .Include(p => p.Shop)
                    .ThenInclude(s => s.User)
                .Where(p => p.IsAvailable && p.Status == 1)
                .OrderByDescending(p => p.Id)
                .Select(p => new {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.Description,
                    p.ImageUrl,
                    p.IsAvailable,
                    p.Status,
                    // Đảm bảo StatusText luôn có giá trị cho App
                    StatusText = p.Status == 1 ? "Approved" : (p.Status == 0 ? "Pending" : "Rejected"),
                    p.ShopId,
                    p.CategoryId,
                    SellerName = (p.Shop != null && p.Shop.User != null) ? p.Shop.User.FullName : (p.Shop != null ? p.Shop.Name : "Quán ăn Lang Food")
                })
                .ToListAsync();
        }

        // 2. LẤY CHI TIẾT MỘT MÓN ĂN
        [HttpGet("{id}")]
        public async Task<ActionResult<object>> GetProduct(int id)
        {
            var product = await _context.Products
                .Include(p => p.Shop)
                    .ThenInclude(s => s.User)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (product == null) return NotFound(new { message = "Không tìm thấy món này!" });

            return Ok(new
            {
                product.Id,
                product.Name,
                product.Price,
                product.Description,
                product.ImageUrl,
                product.IsAvailable,
                product.Status,
                product.ShopId,
                product.CategoryId,
                SellerName = product.Shop?.User?.FullName ?? product.Shop?.Name,
                SellerPhone = product.Shop?.User?.PhoneNumber
            });
        }

        // 3. LẤY MÓN THEO SHOP ID (Dùng cho Quản lý món ăn của Seller)
        [HttpGet("shop/{shopId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetProductsByShop(int shopId)
        {
            // Trả về tất cả các món để chủ quán theo dõi trạng thái duyệt
            return await _context.Products
                .Where(p => p.ShopId == shopId)
                .OrderByDescending(p => p.Id)
                .Select(p => new {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.Description,
                    p.ImageUrl,
                    p.IsAvailable,
                    p.Status,
                    p.ShopId,
                    p.CategoryId,
                    // Củng cố logic StatusText cho dữ liệu cũ
                    StatusText = p.Status == 1 ? "Approved" : (p.Status == 0 ? "Pending" : "Rejected")
                })
                .ToListAsync();
        }

        // 3b. LẤY MÓN THEO SELLER ID (Dành cho bản Android cũ hoặc tìm nhanh)
        [HttpGet("seller/{sellerId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetProductsBySeller(string sellerId)
        {
            var shop = await _context.Shops.FirstOrDefaultAsync(s => s.UserId == sellerId);
            if (shop == null) return NotFound(new { message = "Không tìm thấy Shop!" });

            return await _context.Products
                .Where(p => p.ShopId == shop.Id)
                .OrderByDescending(p => p.Id)
                .Select(p => new {
                    p.Id,
                    p.Name,
                    p.Price,
                    p.Description,
                    p.ImageUrl,
                    p.IsAvailable,
                    p.Status,
                    p.ShopId,
                    p.CategoryId,
                    // Củng cố logic StatusText cho dữ liệu cũ
                    StatusText = p.Status == 1 ? "Approved" : (p.Status == 0 ? "Pending" : "Rejected")
                })
                .ToListAsync();
        }

        // 4. ĐĂNG MÓN ĂN KÈM FILE ẢNH (Khớp với ApiService.java và AddFoodActivity.java)
        [HttpPost("upload")]
        public async Task<ActionResult<Product>> PostProductWithImage(
            [FromForm] string name,
            [FromForm] decimal price,
            [FromForm] string description,
            [FromForm] int shopId, // Nhận trực tiếp shopId từ App
            [FromForm] int categoryId,
            IFormFile image)
        {
            var shopExists = await _context.Shops.AnyAsync(s => s.Id == shopId);
            if (!shopExists) return BadRequest(new { message = "Shop không tồn tại!" });

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
                ShopId = shopId,
                CategoryId = categoryId,
                ImageUrl = imageUrl,
                IsAvailable = true,
                Status = 0 // Đợi Admin duyệt
            };

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            return Ok(product);
        }

        // 5. CẬP NHẬT MÓN ĂN
        [HttpPut("{id}")]
        public async Task<IActionResult> PutProduct(int id, Product updatedProduct)
        {
            if (id != updatedProduct.Id) return BadRequest(new { message = "ID không khớp!" });

            var existingProduct = await _context.Products.FindAsync(id);
            if (existingProduct == null) return NotFound(new { message = "Không tìm thấy món ăn!" });

            // Cập nhật thông tin món ăn
            existingProduct.Name = updatedProduct.Name;
            existingProduct.Price = updatedProduct.Price;
            existingProduct.Description = updatedProduct.Description;
            existingProduct.CategoryId = updatedProduct.CategoryId;
            
            if (!string.IsNullOrEmpty(updatedProduct.ImageUrl))
            {
                existingProduct.ImageUrl = updatedProduct.ImageUrl;
            }

            // Reset trạng thái về Chờ duyệt (Status = 0) khi có bất kỳ thay đổi nào
            existingProduct.Status = 0;
            existingProduct.IsAvailable = true;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!_context.Products.Any(e => e.Id == id)) return NotFound();
                else throw;
            }

            return Ok(new { success = true, message = "Cập nhật thành công! Món ăn đã được gửi lại để Admin phê duyệt." });
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
    }
}