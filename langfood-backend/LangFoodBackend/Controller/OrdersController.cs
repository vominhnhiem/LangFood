using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using LangFood.Shared.DTOs;
using LangFood.Shared.DTOs.LangFood.Shared.DTOs;
using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LangFoodBackend.Controllers
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

        // --- 1. TẠO ĐƠN HÀNG MỚI ---
        [HttpPost]
        public async Task<ActionResult<Order>> CreateOrder(Order order)
        {
            try
            {
                order.CreatedAt = DateTime.Now;
                order.Status = "Pending";
                _context.Orders.Add(order);
                await _context.SaveChangesAsync();
                return Ok(order);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi tạo đơn: " + ex.Message });
            }
        }

        // --- 2. LẤY LỊCH SỬ CHO NGƯỜI MUA ---
        [HttpGet("buyer/{buyerId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersByBuyer(string buyerId)
        {
            buyerId = buyerId.Replace("\"", "");
            var orders = await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o => o.BuyerId == buyerId)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
            return Ok(orders);
        }

        // --- 3. QUÁN XÁC NHẬN ĐƠN (Chế biến) ---
        [HttpPut("shop-accept/{id}")]
        public async Task<IActionResult> ShopAcceptOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            order.Status = "Preparing";
            await _context.SaveChangesAsync();
            return Ok();
        }

        // --- 4. QUÁN BÁO ĐÃ NẤU XONG ---
        [HttpPut("shop-ready/{id}")]
        public async Task<IActionResult> ShopReadyOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            order.Status = "Ready";
            await _context.SaveChangesAsync();
            return Ok();
        }

        // --- 5. FIX: LẤY ĐƠN CHO SHIPPER (Đã sửa logic để không bị mất đơn sau khi nhận) ---
        [HttpGet("available-for-shipper/{shipperId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersForShipper(int shipperId)
        {
            // Shipper sẽ thấy 2 loại đơn:
            // 1. Đơn mới đang chờ (Ready/Confirmed) và CHƯA có ai nhận (ShipperId == null)
            // 2. Đơn ĐANG GIAO (Delivering) bởi CHÍNH Shipper này (ShipperId == shipperId)
            return await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o =>
                    ((o.Status == "Ready" || o.Status == "Confirmed" || o.Status == "Accepted") && o.ShipperId == null) ||
                    (o.Status == "Delivering" && o.ShipperId == shipperId)
                )
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
        }

        // --- 6. SHIPPER NHẬN ĐƠN ---
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] int shipperId)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            // Nếu đơn đã có người nhận rồi thì báo lỗi
            if (order.ShipperId != null && order.ShipperId != shipperId)
                return BadRequest("Đơn hàng đã có người khác nhận.");

            // Chỉ cho phép nhận đơn ở các trạng thái chờ
            if (order.Status != "Ready" && order.Status != "Confirmed" && order.Status != "Accepted")
                return BadRequest("Đơn hàng không ở trạng thái có thể nhận.");

            var shipper = await _context.Shippers.FindAsync(shipperId);
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
            decimal amountToHold = (decimal)(order.TotalAmount + order.ShippingFee);

            if (wallet == null || wallet.Balance < amountToHold)
                return BadRequest("Số dư ví không đủ để nhận đơn.");

            // Thực hiện giam tiền
            wallet.Balance -= amountToHold;
            _context.Transactions.Add(new Transaction
            {
                WalletId = wallet.Id,
                Amount = -amountToHold,
                Type = "ORDER_HOLD",
                Description = $"Giam tiền đơn #{order.Id}",
                Status = 1,
                OrderId = order.Id,
                CreatedAt = DateTime.Now
            });

            order.ShipperId = shipperId;
            order.Status = "Delivering";
            await _context.SaveChangesAsync();
            return Ok();
        }

        // --- 7. HOÀN THÀNH ĐƠN HÀNG (Sửa tiền công khớp App) ---
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == id);
            if (order == null || order.Status == "Completed") return Ok();

            order.Status = "Completed";
            order.DeliveredAt = DateTime.Now;

            decimal foodAmount = (decimal)order.TotalAmount;
            decimal systemFee = (decimal)order.ShippingFee;
            decimal shipperPay = 10000; // Khớp với 10k hiển thị trên App của bạn

            var shop = await _context.Shops.FindAsync(order.ShopId);
            if (shop != null)
            {
                var shopWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shop.UserId);
                if (shopWallet != null)
                {
                    shopWallet.Balance += foodAmount;
                    _context.Transactions.Add(new Transaction { WalletId = shopWallet.Id, Amount = foodAmount, Type = "ORDER_REVENUE", Description = $"Doanh thu đơn #{order.Id}", Status = 1, OrderId = order.Id, CreatedAt = DateTime.Now });
                }
            }

            if (order.ShipperId.HasValue)
            {
                var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                var sw = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                if (sw != null)
                {
                    decimal holdAmount = foodAmount + systemFee;
                    decimal totalBack = (order.PaymentMethod == 0) ? shipperPay : (holdAmount + shipperPay);
                    sw.Balance += totalBack;
                    _context.Transactions.Add(new Transaction { WalletId = sw.Id, Amount = totalBack, Type = "SHIPPER_EARNING", Description = $"Hoàn vốn/Công đơn #{order.Id}", Status = 1, OrderId = order.Id, CreatedAt = DateTime.Now });
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Thành công" });
        }

        // --- 8. DASHBOARD & SHOP OPS ---
        [HttpGet("shop-stats/{shopId}")]
        public async Task<ActionResult<DetailedShopStatsDto>> GetShopStats(int shopId)
        {
            var now = DateTime.Now;
            var allShopOrders = await _context.Orders.Where(o => o.ShopId == shopId).ToListAsync();
            return Ok(new DetailedShopStatsDto
            {
                TodayOrderCount = allShopOrders.Count(o => o.CreatedAt.Date == now.Date),
                TodayRevenue = allShopOrders.Where(o => o.CreatedAt.Date == now.Date && o.Status == "Completed").Sum(o => (decimal)o.TotalAmount),
                MonthRevenue = allShopOrders.Where(o => o.CreatedAt.Month == now.Month && o.CreatedAt.Year == now.Year && o.Status == "Completed").Sum(o => (decimal)o.TotalAmount)
            });
        }

        [HttpGet("shop/{shopId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersByShop(int shopId)
        {
            return await _context.Orders.Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o => o.ShopId == shopId).OrderByDescending(o => o.CreatedAt).ToListAsync();
        }

        [HttpGet("shop-stats-detailed/{shopId}")]
        public async Task<ActionResult<DetailedShopStatsDto>> GetDetailedShopStats(int shopId, [FromQuery] string startDate, [FromQuery] string endDate)
        {
            DateTime start = DateTime.Parse(startDate).Date;
            DateTime end = DateTime.Parse(endDate).Date.AddDays(1).AddTicks(-1);
            var filtered = await _context.Orders.Where(o => o.ShopId == shopId && o.CreatedAt >= start && o.CreatedAt <= end).ToListAsync();
            return Ok(new DetailedShopStatsDto
            {
                TotalOrders = filtered.Count,
                SuccessOrders = filtered.Count(o => o.Status == "Completed"),
                FailedOrders = filtered.Count(o => o.Status == "Cancelled" || o.Status == "Rejected"),
                TotalRevenue = filtered.Where(o => o.Status == "Completed").Sum(o => (decimal)o.TotalAmount)
            });
        }
    }
}