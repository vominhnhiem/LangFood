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

        // 1. Buyer Đặt hàng
        [HttpPost]
        public async Task<ActionResult<Order>> PostOrder(Order order)
        {
            if (order == null) return BadRequest(new { message = "Dữ liệu trống!" });
            try
            {
                order.CreatedAt = DateTime.Now;
                order.Status = "Pending";
                order.Buyer = null; // Tránh EF cố tạo mới User
                order.Shop = null;
                order.Shipper = null;

                if (order.OrderItems != null)
                {
                    foreach (var item in order.OrderItems)
                    {
                        item.Order = null;
                        item.Product = null;
                    }
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

        // 2. Lấy đơn hàng cho SHOP (Theo ShopId kiểu int)
        [HttpGet("shop/{shopId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetOrdersByShop(int shopId)
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o => o.ShopId == shopId)
                .OrderByDescending(o => o.CreatedAt)
                .Select(o => new {
                    o.Id,
                    o.BuyerId,
                    o.BuyerName,
                    o.Status,
                    o.TotalAmount,
                    o.ShippingFee,
                    o.CreatedAt,
                    o.DeliveryBuilding,
                    o.DeliveryRoom,
                    OrderItems = o.OrderItems.Select(oi => new {
                        oi.ProductId,
                        ProductName = oi.Product.Name,
                        oi.Product.ImageUrl,
                        oi.Quantity,
                        oi.UnitPrice
                    })
                })
                .ToListAsync();
            return Ok(orders);
        }

        // 3. Lấy đơn hàng cho Shipper (Các đơn đã xác nhận và chưa có người nhận)
        [HttpGet("available")]
        public async Task<ActionResult<IEnumerable<Order>>> GetAvailableOrders()
        {
            return await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o => o.Status == "Confirmed" && o.ShipperId == null)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
        }

        // 4. Shipper nhận đơn (Dùng shipperId kiểu int)
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] int shipperId)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            if (order.ShipperId != null) return BadRequest(new { message = "Đã có người nhận rồi!" });

            order.ShipperId = shipperId;
            order.Status = "Shipping";
            await _context.SaveChangesAsync();
            return Ok(new { message = "Nhận đơn thành công" });
        }

        // 5. Shop xác nhận đơn
        [HttpPut("confirm/{id}")]
        public async Task<IActionResult> ConfirmOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            order.Status = "Confirmed";
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xác nhận đơn" });
        }

        // 6. Hoàn thành đơn
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            order.Status = "Delivered";
            order.DeliveredAt = DateTime.Now;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Giao hàng thành công!" });
        }
    }
}