using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LangFoodBackend.Controllers
{
        [Route("api/[controller]")]
        [ApiController]
        public class ShopsController : ControllerBase
        {
            private readonly LangFoodDbContext _context; // Thay bằng DbContext của bạn

            public ShopsController(LangFoodDbContext context) { _context = context; }

            [HttpGet("user/{userId}")]
            public async Task<IActionResult> GetShopByUserId(string userId)
            {
                var shop = await _context.Shops.FirstOrDefaultAsync(s => s.UserId == userId);
                if (shop == null) return NotFound();
                return Ok(shop);
            }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetShop(int id)
        {
            // Sử dụng Include để lấy thông tin User
            var shop = await _context.Shops
                .Include(s => s.User)
                .FirstOrDefaultAsync(s => s.Id == id);

            if (shop == null) return NotFound();

            // Bạn có thể trả về một Object mới chứa thêm trường OwnerName
            return Ok(new
            {
                shop.Id,
                shop.Name,
                shop.Address,
                shop.Description,
                shop.ImageUrl,
                shop.IsOpen,
                shop.UserId,
                OwnerName = shop.User?.FullName ?? "Chủ quán" // Lấy tên người bán ở đây
            });
        }

        [HttpPut("{id}/toggle-status")]
            public async Task<IActionResult> ToggleShopStatus(int id)
            {
                var shop = await _context.Shops.FindAsync(id);
                if (shop == null) return NotFound(new { message = "Không tìm thấy quán!" });

                shop.IsOpen = !shop.IsOpen;
                await _context.SaveChangesAsync();

                return Ok(shop);
            }

            [HttpPut("{id}")]
            public async Task<IActionResult> UpdateShop(int id, [FromBody] Shop updatedShop)
            {
                var shop = await _context.Shops.FindAsync(id);
                if (shop == null) return NotFound(new { message = "Không tìm thấy cửa hàng" });

                shop.Name = updatedShop.Name;
                shop.Address = updatedShop.Address;
                shop.Description = updatedShop.Description;

                await _context.SaveChangesAsync();
                return Ok(shop);
            }

            [HttpPost("upload-image/{shopId}")]
            public async Task<IActionResult> UploadShopImage(int shopId, IFormFile image)
            {
                var shop = await _context.Shops.FindAsync(shopId);
                if (shop == null) return NotFound();

                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "shops");
                if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

                var uniqueFileName = Guid.NewGuid().ToString() + "_" + image.FileName;
                var filePath = Path.Combine(uploadsFolder, uniqueFileName);
                using (var fileStream = new FileStream(filePath, FileMode.Create))
                {
                    await image.CopyToAsync(fileStream);
                }

                shop.ImageUrl = "/images/shops/" + uniqueFileName;
                await _context.SaveChangesAsync();
                return Ok(new { message = "Upload thành công", url = shop.ImageUrl });
            }
        }
}
