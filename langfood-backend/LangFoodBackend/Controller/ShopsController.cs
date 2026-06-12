using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;

namespace LangFoodBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ShopsController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public ShopsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. Lấy thông tin Shop theo ID của Shop
        [HttpGet("{id}")]
        public async Task<IActionResult> GetShopById(int id)
        {
            var shop = await _context.Shops
                .Include(s => s.User) // Bao gồm thông tin chủ shop nếu cần
                .FirstOrDefaultAsync(s => s.Id == id);

            if (shop == null)
            {
                return NotFound(new { message = "Không tìm thấy cửa hàng." });
            }

            return Ok(shop);
        }

        // 2. Lấy thông tin Shop theo UserId (Dùng để hiển thị thông tin khi Seller vào trang chỉnh sửa)
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetShopByUserId(string userId)
        {
            var shop = await _context.Shops.FirstOrDefaultAsync(s => s.UserId == userId);

            if (shop == null)
            {
                return NotFound(new { message = "Người dùng này không có cửa hàng." });
            }

            return Ok(shop);
        }

        // 3. Cập nhật thông tin Shop (Dùng cho màn hình Chỉnh sửa thông tin của Seller)
        // Seller sẽ nhập Address thay vì chọn Tòa nhà/Phòng
        [HttpPut("update-info/{userId}")]
        public async Task<IActionResult> UpdateShopInfo(string userId, [FromBody] Shop updateDto)
        {
            var shop = await _context.Shops.FirstOrDefaultAsync(s => s.UserId == userId);
            if (shop == null)
            {
                return NotFound(new { message = "Không tìm thấy thông tin cửa hàng để cập nhật." });
            }

            // Chỉ cập nhật các trường liên quan đến thông tin hiển thị của quán
            shop.Name = updateDto.Name;
            shop.Address = updateDto.Address; // Đây là phần nhập địa chỉ thay cho Tòa nhà/Phòng
            shop.Description = updateDto.Description;

            if (!string.IsNullOrEmpty(updateDto.ImageUrl))
            {
                shop.ImageUrl = updateDto.ImageUrl;
            }

            try
            {
                _context.Shops.Update(shop);
                await _context.SaveChangesAsync();
                return Ok(new { success = true, message = "Cập nhật thông tin cửa hàng thành công!", data = shop });
            }
            catch (DbUpdateException ex)
            {
                return BadRequest(new { message = "Lỗi khi cập nhật dữ liệu: " + ex.Message });
            }
        }
    }
}