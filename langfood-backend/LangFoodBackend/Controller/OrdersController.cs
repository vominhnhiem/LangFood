using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodBackend.Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public OrdersController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. Lấy toàn bộ danh sách đơn hàng
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrders()
        {
            return await _context.Orders
                .Include(o => o.OrderItems)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
        }

        // 2. Buyer Đặt hàng
        [HttpPost]
        public async Task<ActionResult<Order>> PostOrder(Order order)
        {
            if (order == null) return BadRequest(new { message = "Dữ liệu trống!" });

            try
            {
                // SỬA TẠI ĐÂY: Gán trực tiếp DateTime.Now (không dùng .ToString)
                order.CreatedAt = DateTime.Now;
                order.Status = "Pending";

                order.Buyer = null;
                order.Shipper = null;

                foreach (var item in order.OrderItems)
                {
                    item.Order = null;
                    item.Product = null;
                }

                _context.Orders.Add(order);
                await _context.SaveChangesAsync();

                return Ok(order);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi: " + ex.Message });
            }
        }

        // 3. Lấy đơn hàng theo BuyerId
        [HttpGet("buyer/{buyerId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersByBuyer(string buyerId)
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems)
                .Where(o => o.BuyerId == buyerId)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
            return Ok(orders);
        }

        // 4. Xóa đơn hàng
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            _context.Orders.Remove(order);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // 5. Lấy đơn hàng cho Shipper
        [HttpGet("available")]
        public async Task<ActionResult<IEnumerable<Order>>> GetAvailableOrders()
        {
            var orders = await _context.Orders
                .Include(o => o.Buyer) // THÊM DÒNG NÀY ĐỂ LẤY TÊN KHÁCH
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product) // Đã có cái này để lấy món ăn
                .Where(o => o.Status == "Pending" && string.IsNullOrEmpty(o.ShipperId))
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
            return Ok(orders);
        }

        // 6. Shipper nhận đơn
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] string shipperId)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            if (!string.IsNullOrEmpty(order.ShipperId)) return BadRequest(new { message = "Đã có người nhận" });

            order.ShipperId = shipperId;
            order.Status = "Shipping";

            _context.Orders.Update(order);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Nhận đơn thành công" });
        }

        // 7. Xác nhận giao hàng thành công
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            order.Status = "Delivered";
            // SỬA TẠI ĐÂY: Gán trực tiếp DateTime.Now
            order.DeliveredAt = DateTime.Now;

            _context.Orders.Update(order);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Giao hàng thành công!" });
        }
    }
}