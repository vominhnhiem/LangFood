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

        // 1. Lấy đơn cho Shipper (Đơn Ready chưa ai nhận + Đơn mình đang giao)
        // API này cực kỳ quan trọng để Shipper thấy lại đơn sau khi lỡ thoát app
        [HttpGet("available-for-shipper/{shipperId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersForShipper(int shipperId)
        {
            var orders = await _context.Orders
                .Where(o => (o.Status == "Ready" && o.ShipperId == null)
                         || (o.ShipperId == shipperId && o.Status == "Delivering"))
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();

            return Ok(orders);
        }

        // 2. Shipper nhận đơn và TỰ ĐỘNG GIAM TIỀN (Ví dụ giam 28k)
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] int shipperId)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            // Chặn nếu đơn đã có người nhận hoặc chưa sẵn sàng
            if (order.ShipperId != null) return BadRequest(new { message = "Đơn này đã có người nhận!" });
            if (order.Status != "Ready") return BadRequest(new { message = "Đơn chưa sẵn sàng." });

            var shipper = await _context.Shippers.FindAsync(shipperId);
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);

            // Tiền giam = Tiền món + 3k phí dịch vụ
            decimal amountToHold = order.TotalAmount + order.ShippingFee;

            if (wallet == null || wallet.Balance < amountToHold)
                return BadRequest(new { message = "Số dư ví không đủ để nhận đơn này." });

            // Trừ tiền giam
            wallet.Balance -= amountToHold;
            _context.Transactions.Add(new Transaction
            {
                WalletId = wallet.Id,
                Amount = amountToHold,
                Type = "HOLD_ORDER",
                Description = $"Giam {amountToHold:N0}đ bảo đảm đơn #{order.Id}",
                Status = 1,
                OrderId = order.Id,
                CreatedAt = DateTime.Now
            });

            order.ShipperId = shipperId;
            order.Status = "Delivering";
            await _context.SaveChangesAsync();

            return Ok(new { message = "Nhận đơn thành công." });
        }

        // 3. Hoàn thành đơn: HOÀN 25k (món) + CỘNG 20k (công) = 45k
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null || order.Status != "Delivering") return BadRequest();

            if (order.ShipperId.HasValue)
            {
                var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                if (wallet != null)
                {
                    // Hoàn lại tiền món + Thưởng 20k công ship
                    decimal amountToRefund = order.TotalAmount;
                    decimal bonus = 20000;
                    decimal totalBack = amountToRefund + bonus;

                    wallet.Balance += totalBack;
                    _context.Transactions.Add(new Transaction
                    {
                        WalletId = wallet.Id,
                        Amount = totalBack,
                        Type = "REFUND_BONUS",
                        Description = $"Hoàn {amountToRefund:N0}đ món + 20k công ship đơn #{order.Id}",
                        Status = 1,
                        OrderId = order.Id,
                        CreatedAt = DateTime.Now
                    });
                }
            }

            order.Status = "Completed";
            order.DeliveredAt = DateTime.Now;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Giao hàng hoàn tất." });
        }

        // --- CÁC API CƠ BẢN KHÁC (GIỮ NGUYÊN) ---
        [HttpPost]
        public async Task<ActionResult<Order>> CreateOrder([FromBody] Order order)
        {
            order.CreatedAt = DateTime.Now; order.Status = "Pending";
            _context.Orders.Add(order); await _context.SaveChangesAsync(); return Ok(order);
        }
        [HttpGet("buyer/{buyerId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersByBuyer(string buyerId)
        {
            return await _context.Orders.Where(o => o.BuyerId == buyerId).Include(o => o.OrderItems).ThenInclude(oi => oi.Product).OrderByDescending(o => o.CreatedAt).ToListAsync();
        }
        [HttpGet("shop/{shopId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersByShop(int shopId)
        {
            return await _context.Orders.Where(o => o.ShopId == shopId).Include(o => o.OrderItems).ThenInclude(oi => oi.Product).OrderByDescending(o => o.CreatedAt).ToListAsync();
        }
        [HttpPut("shop-accept/{id}")]
        public async Task<IActionResult> ShopAcceptOrder(int id)
        {
            var o = await _context.Orders.FindAsync(id); if (o == null) return NotFound(); o.Status = "Preparing"; await _context.SaveChangesAsync(); return Ok();
        }
        [HttpPut("shop-ready/{id}")]
        public async Task<IActionResult> ShopReadyOrder(int id)
        {
            var o = await _context.Orders.FindAsync(id); if (o == null) return NotFound(); o.Status = "Ready"; await _context.SaveChangesAsync(); return Ok();
        }
    }
}