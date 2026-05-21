using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodBackend.Controller
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

        // 1. Lấy giỏ hàng kèm Topping và Ghi chú
        [HttpGet("{userId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetCart(string userId)
        {
            var cartItems = await _context.CartItems
                .Include(c => c.Product)
                .Where(c => c.UserId == userId)
                .Select(c => new {
                    product = c.Product,
                    quantity = c.Quantity,
                    note = c.Note,
                    selectedOptions = c.SelectedOptionsJson
                })
                .ToListAsync();

            return Ok(cartItems);
        }

        // 2. Thêm vào giỏ: Hỗ trợ Topping và Note
        [HttpPost]
        public async Task<IActionResult> AddToCart(string userId, int productId, int quantity, [FromQuery] string? note, [FromQuery] string? selectedOptions)
        {
            // Tìm món: Phải khớp ProductId AND Note AND Topping mới cộng dồn số lượng
            var existingItem = await _context.CartItems
                .FirstOrDefaultAsync(c => c.UserId == userId &&
                                          c.ProductId == productId &&
                                          c.Note == note &&
                                          c.SelectedOptionsJson == selectedOptions);

            if (existingItem != null)
            {
                existingItem.Quantity += quantity;
                _context.CartItems.Update(existingItem);
            }
            else
            {
                var newItem = new CartItem
                {
                    UserId = userId,
                    ProductId = productId,
                    Quantity = quantity,
                    Note = note,
                    SelectedOptionsJson = selectedOptions
                };
                _context.CartItems.Add(newItem);
            }

            await _context.SaveChangesAsync();
            return Ok();
        }

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