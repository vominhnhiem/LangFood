using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LangFoodBackend.Controllers
{
    /// <summary>
    /// Controller mô phỏng đơn hàng KTX dùng cho chế độ thử nghiệm (Demo/Test mode).
    /// Cho phép Flutter app tạo, lấy danh sách và cập nhật trạng thái đơn test
    /// mà không ảnh hưởng đến bảng Orders chính.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class OrderTestsController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public OrderTestsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // ─── POST api/OrderTests ──────────────────────────────────────────────
        // Tạo đơn test mới (được gọi từ CheckoutScreen khi ở chế độ thử nghiệm)
        [HttpPost]
        public async Task<IActionResult> CreateOrderTest([FromBody] OrderTest order)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            order.Id = 0; // Reset để SQL Server tự sinh IDENTITY
            order.CreatedAt = DateTime.Now;
            order.Status = string.IsNullOrWhiteSpace(order.Status) ? "Ready" : order.Status;

            _context.OrderTests.Add(order);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetOrderTest), new { id = order.Id }, order);
        }

        // ─── GET api/OrderTests/{id} ──────────────────────────────────────────
        [HttpGet("{id}")]
        public async Task<IActionResult> GetOrderTest(int id)
        {
            var order = await _context.OrderTests.FindAsync(id);
            if (order == null) return NotFound();
            return Ok(order);
        }

        // ─── GET api/OrderTests/available?shipperId=1 ─────────────────────────
        // Lấy danh sách đơn Ready (hoặc đơn đang giao của shipper)
        [HttpGet("available")]
        public async Task<IActionResult> GetAvailableOrders([FromQuery] int? shipperId)
        {
            IQueryable<OrderTest> query = _context.OrderTests;

            if (shipperId.HasValue)
            {
                query = query.Where(o =>
                    o.Status == "Ready" ||
                    (o.ShipperId == shipperId.Value && o.Status == "Delivering"));
            }
            else
            {
                query = query.Where(o => o.Status == "Ready");
            }

            var orders = await query
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            return Ok(orders);
        }

        // ─── PUT api/OrderTests/accept/{id}?shipperId=1 ──────────────────────
        // Shipper nhận đơn → cập nhật Status = "Delivering"
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] int shipperId)
        {
            var order = await _context.OrderTests.FindAsync(id);
            if (order == null) return NotFound(new { message = $"Không tìm thấy đơn test #{id}" });

            order.Status = "Delivering";
            order.ShipperId = shipperId;
            await _context.SaveChangesAsync();

            return Ok(order);
        }

        // ─── PUT api/OrderTests/complete/{id} ────────────────────────────────
        // Shipper giao xong → cập nhật Status = "Completed"
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.OrderTests.FindAsync(id);
            if (order == null) return NotFound(new { message = $"Không tìm thấy đơn test #{id}" });

            order.Status = "Completed";
            await _context.SaveChangesAsync();

            return Ok(order);
        }

        // ─── GET api/OrderTests ───────────────────────────────────────────────
        // Lấy tất cả đơn test (dành cho admin/debug)
        [HttpGet]
        public async Task<IActionResult> GetAllOrders()
        {
            var orders = await _context.OrderTests
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
            return Ok(orders);
        }

        // ─── DELETE api/OrderTests/{id} ───────────────────────────────────────
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOrderTest(int id)
        {
            var order = await _context.OrderTests.FindAsync(id);
            if (order == null) return NotFound();
            _context.OrderTests.Remove(order);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
}

