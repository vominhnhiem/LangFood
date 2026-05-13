using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LangFoodBackend.Controller
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
        }
}
