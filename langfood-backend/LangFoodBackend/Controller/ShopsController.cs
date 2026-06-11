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

        // 1. Lấy thông tin Shop theo ID của Shop (Dùng cho chi tiết đơn hàng)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetShopById(int id)
        {
            var shop = await _context.Shops.FindAsync(id);

            if (shop == null)
            {
                return NotFound(new { message = "Không tìm thấy cửa hàng." });
            }

            return Ok(shop);
        }

        // 2. Lấy thông tin Shop theo UserId của chủ shop
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
    }
}