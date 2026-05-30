using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodBackend.Controllers
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

        // 1. LẤY TẤT CẢ MÓN ĂN (Trang chủ App - Đã thêm Topping)
        [HttpGet]
        public async Task<ActionResult<IEnumerable<object>>> GetProducts([FromQuery] int? categoryId = null, [FromQuery] string? search = null)
        {
            var query = _context.Products
                .Include(p => p.Shop)
                    .ThenInclude(s => s.User)
                .Include(p => p.OptionGroups)
                    .ThenInclude(g => g.Options)
                .Where(p => p.IsAvailable && p.Status == 1 && !p.IsDeleted);

            if (categoryId.HasValue && categoryId.Value != -1)
            {
                query = query.Where(p => p.CategoryId == categoryId.Value);
            }

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(p => p.Name.Contains(search));
            }

            return await query
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
                    SellerName = !string.IsNullOrEmpty(p.Shop.Name) ? p.Shop.Name :
                                 (p.Shop.User != null ? p.Shop.User.FullName : "Quán ăn Lang Food"),
                    IsShopOpen = p.Shop.IsOpen,
                    // Trả về danh sách option groups để App có thể hiển thị sơ bộ hoặc tính giá
                    OptionGroups = p.OptionGroups.Select(g => new {
                        g.Id,
                        g.Name,
                        g.IsRequired,
                        g.MinSelectable,
                        g.MaxSelectable,
                        Options = g.Options.Select(o => new {
                            o.Id,
                            o.Name,
                            o.AdditionalPrice,
                            o.IsAvailable
                        })
                    })
                })
                .ToListAsync();
        }

        // 2. LẤY CHI TIẾT MỘT MÓN ĂN (Dùng để hiển thị màn hình chọn Topping như Grab)
        [HttpGet("{id}")]
        public async Task<ActionResult<object>> GetProduct(int id)
        {
            var product = await _context.Products
                .Include(p => p.Shop)
                    .ThenInclude(s => s.User)
                .Include(p => p.OptionGroups)
                    .ThenInclude(g => g.Options)
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
                SellerName = !string.IsNullOrEmpty(product.Shop?.Name) ? product.Shop.Name :
                             (product.Shop?.User?.FullName ?? "Quán ăn Lang Food"),
                SellerPhone = product.Shop?.User?.PhoneNumber,
                IsShopOpen = product.Shop != null ? product.Shop.IsOpen : true,
                // Trả về cấu trúc Topping chi tiết
                OptionGroups = product.OptionGroups.Select(g => new {
                    g.Id,
                    g.Name,
                    g.IsRequired,
                    g.MinSelectable,
                    g.MaxSelectable,
                    Options = g.Options.Select(o => new {
                        o.Id,
                        o.Name,
                        o.AdditionalPrice,
                        o.IsAvailable
                    })
                })
            });
        }

        // 3. LẤY MÓN THEO SHOP ID
        [HttpGet("shop/{shopId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetProductsByShop(int shopId)
        {
            return await _context.Products
                .Include(p => p.OptionGroups) // Shop cũng cần xem món mình có những topping nào
                .Where(p => p.ShopId == shopId && !p.IsDeleted)
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
                    StatusText = p.Status == 1 ? "Approved" : (p.Status == 0 ? "Pending" : "Rejected")
                })
                .ToListAsync();
        }

        // 4. ĐĂNG MÓN ĂN KÈM FILE ẢNH
        [HttpPost("upload")]
        public async Task<ActionResult<Product>> PostProductWithImage(
            [FromForm] string name,
            [FromForm] decimal price,
            [FromForm] string description,
            [FromForm] int shopId,
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
                Status = 0
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

            existingProduct.Name = updatedProduct.Name;
            existingProduct.Price = updatedProduct.Price;
            existingProduct.Description = updatedProduct.Description;
            existingProduct.CategoryId = updatedProduct.CategoryId;

            if (!string.IsNullOrEmpty(updatedProduct.ImageUrl))
            {
                existingProduct.ImageUrl = updatedProduct.ImageUrl;
            }

            existingProduct.Status = 0;
            existingProduct.IsAvailable = true;

            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Cập nhật thành công! Đang chờ duyệt lại." });
        }

        // 6. XÓA MỀM MÓN ĂN
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();

            product.IsDeleted = true;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa món ăn." });
        }
    }
}
