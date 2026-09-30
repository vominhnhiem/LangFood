using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodBackend.Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrderTestsController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public OrderTestsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. POST /api/OrderTests: Khách hàng chọn điểm trên bản đồ và chốt đơn ➔ Lưu thẳng vào CSDL
        [HttpPost]
        public async Task<ActionResult<OrderTest>> CreateOrderTest([FromBody] OrderTest model)
        {
            if (model == null)
            {
                return BadRequest(new { message = "Dữ liệu đơn hàng không hợp lệ" });
            }

            model.Id = 0; // Đảm bảo tạo mới
            model.CreatedAt = DateTime.Now;
            model.Status = string.IsNullOrEmpty(model.Status) ? "Ready" : model.Status;

            _context.OrderTests.Add(model);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetOrderTestById), new { id = model.Id }, model);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<OrderTest>> GetOrderTestById(int id)
        {
            var order = await _context.OrderTests.FindAsync(id);
            if (order == null)
            {
                return NotFound(new { message = "Không tìm thấy đơn hàng test" });
            }
            return Ok(order);
        }

        // 2. GET /api/OrderTests/available: Shipper mở app lên lấy danh sách đơn mới đang chờ nhận (hoặc đơn đang giao của shipper đó)
        [HttpGet("available")]
        public async Task<ActionResult<IEnumerable<OrderTest>>> GetAvailableOrderTests([FromQuery] int? shipperId)
        {
            var query = _context.OrderTests.AsQueryable();

            if (shipperId.HasValue)
            {
                // Lấy đơn có status Ready (chưa ai nhận) HOẶC đơn đã được shipper này nhận (Delivering)
                query = query.Where(o => o.Status == "Ready" || (o.ShipperId == shipperId.Value && o.Status != "Completed"));
            }
            else
            {
                // Chỉ lấy đơn đang chờ nhận
                query = query.Where(o => o.Status == "Ready");
            }

            var list = await query.OrderByDescending(o => o.CreatedAt).ToListAsync();
            return Ok(list);
        }

        // 3. PUT /api/OrderTests/accept/{id}?shipperId={shipperId}: Shipper bấm "Nhận đơn ngay"
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrderTest(int id, [FromQuery] int shipperId)
        {
            var order = await _context.OrderTests.FindAsync(id);
            if (order == null)
            {
                return NotFound(new { message = "Không tìm thấy đơn hàng" });
            }

            if (order.Status != "Ready")
            {
                return BadRequest(new { message = "Đơn hàng này đã có shipper khác nhận hoặc đã hoàn thành!" });
            }

            order.Status = "Delivering";
            order.ShipperId = shipperId;

            _context.OrderTests.Update(order);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Nhận đơn thành công", order });
        }

        // 4. PUT /api/OrderTests/complete/{id}: Hoàn thành đơn hàng
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrderTest(int id)
        {
            var order = await _context.OrderTests.FindAsync(id);
            if (order == null)
            {
                return NotFound(new { message = "Không tìm thấy đơn hàng" });
            }

            order.Status = "Completed";

            _context.OrderTests.Update(order);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Hoàn thành đơn hàng thành công", order });
        }
    }
}
