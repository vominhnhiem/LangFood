using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFood.Shared; // Để nhận diện LangFoodDbContext
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.IO;
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

        // 1. Đặt hàng từ App (POST api/Orders)
        [HttpPost]
        public async Task<ActionResult<Order>> CreateOrder([FromBody] Order order)
        {
            try
            {
                order.CreatedAt = DateTime.Now;
                order.Status = "Pending"; // Trạng thái chờ thanh toán hoặc chờ duyệt

                _context.Orders.Add(order);
                await _context.SaveChangesAsync();

                return Ok(order);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi đặt hàng: " + ex.Message });
            }
        }

        // 2. Lấy lịch sử đơn hàng của Người mua (GET api/Orders/buyer/{buyerId})
        [HttpGet("buyer/{buyerId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersByBuyer(string buyerId)
        {
            var orders = await _context.Orders
                .Where(o => o.BuyerId == buyerId)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            return Ok(orders);
        }

        // 3. Lấy đơn hàng của Shop (GET api/Orders/shop/{shopId})
        [HttpGet("shop/{shopId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersByShop(int shopId)
        {
            var orders = await _context.Orders
                .Where(o => o.ShopId == shopId)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            return Ok(orders);
        }

        // 4. Lấy danh sách đơn hàng cho Shipper (GET api/Orders/available)
        [HttpGet("available")]
        public async Task<ActionResult<IEnumerable<Order>>> GetAvailableOrders()
        {
            // Đơn hàng đã được Shop nấu xong (Ready) và chưa có ai nhận
            var orders = await _context.Orders
                .Where(o => o.Status == "Ready" && o.ShipperId == null)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            return Ok(orders);
        }

        // 5. Shop xác nhận nhận đơn (PUT api/Orders/shop-accept/{id})
        [HttpPut("shop-accept/{id}")]
        public async Task<IActionResult> ShopAcceptOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            order.Status = "Preparing"; // Đang chuẩn bị món
            await _context.SaveChangesAsync();
            return Ok(new { message = "Shop đã nhận đơn và đang chuẩn bị món." });
        }

        // 6. Shipper nhận đơn và đặt cọc (PUT api/Orders/accept/{id}?shipperId=...)
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] int shipperId)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            if (order.Status != "Ready")
                return BadRequest(new { message = "Đơn hàng chưa sẵn sàng để nhận." });

            order.ShipperId = shipperId;
            order.Status = "Delivering"; // Đang giao hàng
            await _context.SaveChangesAsync();

            return Ok(new { message = "Shipper đã nhận đơn thành công." });
        }

        // 7. Hoàn thành đơn hàng (PUT api/Orders/complete/{id})
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            order.Status = "Completed";
            order.DeliveredAt = DateTime.Now;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đơn hàng đã hoàn thành." });
        }

        // 8. Admin duyệt đơn (Nếu cần) (PUT api/Orders/admin-approve/{id})
        [HttpPut("admin-approve/{id}")]
        public async Task<IActionResult> AdminApproveOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            order.Status = "Approved";
            await _context.SaveChangesAsync();
            return Ok(new { message = "Admin đã duyệt đơn." });
        }

        // 9. Lấy thống kê Shop (GET api/Orders/shop-stats/{shopId})
        [HttpGet("shop-stats/{shopId}")]
        public async Task<IActionResult> GetShopStats(int shopId)
        {
            var orders = await _context.Orders.Where(o => o.ShopId == shopId && o.Status == "Completed").ToListAsync();

            var stats = new
            {
                TotalOrders = orders.Count,
                TotalRevenue = orders.Sum(o => o.TotalAmount)
            };

            return Ok(stats);
        }
    }
}