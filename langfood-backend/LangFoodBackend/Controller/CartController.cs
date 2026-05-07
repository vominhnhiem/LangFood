using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
// Removed stray placeholder using and fixed models namespace

namespace LangFoodBackend.Controller // Thay bằng namespace thật của bạn
{
    [Route("api/[controller]")]
    [ApiController]
    public class CartController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public CartController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. Lấy giỏ hàng của User: GET api/Cart/user123
        [HttpGet("{userId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetCart(string userId)
        {
            var cartItems = await _context.CartItems
                .Include(c => c.Product) // Load thông tin sản phẩm đi kèm
                .Where(c => c.UserId == userId)
                .Select(c => new {
                    product = c.Product,
                    quantity = c.Quantity
                })
                .ToListAsync();

            return Ok(cartItems);
        }

        // 2. Thêm hoặc cập nhật giỏ hàng: POST api/Cart?userId=...&productId=...&quantity=...
        [HttpPost]
        public async Task<IActionResult> AddToCart(string userId, int productId, int quantity)
        {
            // Kiểm tra xem món này đã có trong giỏ hàng của User này chưa
            var existingItem = await _context.CartItems
                .FirstOrDefaultAsync(c => c.UserId == userId && c.ProductId == productId);

            if (existingItem != null)
            {
                // Nếu có rồi thì cộng dồn số lượng
                existingItem.Quantity += quantity;
                _context.CartItems.Update(existingItem);
            }
            else
            {
                // Nếu chưa có thì thêm mới
                var newItem = new CartItem
                {
                    UserId = userId,
                    ProductId = productId,
                    Quantity = quantity
                };
                _context.CartItems.Add(newItem);
            }

            await _context.SaveChangesAsync();
            return Ok();
        }

        // 3. Xóa 1 món khỏi giỏ hàng: DELETE api/Cart/user123/10
        [HttpDelete("{userId}/{productId}")]
        public async Task<IActionResult> RemoveFromCart(string userId, int productId)
        {
            var item = await _context.CartItems
                .FirstOrDefaultAsync(c => c.UserId == userId && c.ProductId == productId);

            if (item == null) return NotFound();

            _context.CartItems.Remove(item);
            await _context.SaveChangesAsync();
            return Ok();
        }

        // 4. Xóa sạch giỏ hàng (sau khi đặt hàng): DELETE api/Cart/user123
        [HttpDelete("{userId}")]
        public async Task<IActionResult> ClearCart(string userId)
        {
            var items = _context.CartItems.Where(c => c.UserId == userId);
            _context.CartItems.RemoveRange(items);
            await _context.SaveChangesAsync();
            return Ok();
        }
    }
}