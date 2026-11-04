using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
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
        [HttpGet("{id}/pickup")]
        public async Task<IActionResult> GetPickup(int id)
        {
            var shop = await _context.Shops.FindAsync(id);
            if (shop == null) return NotFound();

            return Ok(new { shop.Address, latitude = shop.PickupLatitude, longitude = shop.PickupLongitude });
        }

        public sealed record PickupUpdate(string Address, double? Latitude, double? Longitude);

        [Authorize]
        [HttpPut("{id}/pickup")]
        public async Task<IActionResult> UpdatePickup(int id, PickupUpdate update)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();
            var address = update.Address?.Trim();
            if (string.IsNullOrWhiteSpace(address) || address.Length > 500 ||
                update.Latitude is not double latitude || !double.IsFinite(latitude) || Math.Abs(latitude) > 90 ||
                update.Longitude is not double longitude || !double.IsFinite(longitude) || Math.Abs(longitude) > 180)
                return BadRequest(new { message = "Cần địa chỉ và tọa độ điểm lấy món hợp lệ." });

            var shop = await _context.Shops.FirstOrDefaultAsync(s =>
                s.Id == id && s.UserId == userId && s.IsActive &&
                _context.Users.Any(u => u.Id == s.UserId && u.RoleId == 2 && u.IsApproved));
            if (shop == null) return NotFound();

            shop.Address = address;
            shop.PickupLatitude = latitude;
            shop.PickupLongitude = longitude;
            await _context.SaveChangesAsync();
            return NoContent();
        }

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
