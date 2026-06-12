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

                // Nếu chọn Chuyển khoản (PaymentMethod = 1) -> Trạng thái Chờ thanh toán
                // Nếu chọn Tiền mặt (PaymentMethod = 0) -> Trạng thái Chờ xác nhận (Pending)
                order.Status = (order.PaymentMethod == 1) ? "PendingPayment" : "Pending";

                _context.Orders.Add(order);
                await _context.SaveChangesAsync();

                return Ok(order);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi tạo đơn: " + ex.Message });
            }
        }

        // --- 2. HỦY ĐƠN HÀNG (Dùng khi khách bấm Hủy ở màn hình QR) ---
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            // Chỉ cho phép xóa đơn nếu đang ở trạng thái chờ thanh toán hoặc chưa được xử lý
            if (order.Status == "PendingPayment" || order.Status == "Pending")
            {
                _context.Orders.Remove(order);
                await _context.SaveChangesAsync();
                return Ok();
            }
            return BadRequest(new { message = "Không thể hủy đơn hàng đã được phía quán nhận hoặc đang giao." });
        }

        // --- 3. LẤY LỊCH SỬ CHO NGƯỜI MUA ---
        [HttpGet("buyer/{buyerId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersByBuyer(string buyerId)
        {
            buyerId = buyerId.Replace("\"", "");
            var orders = await _context.Orders
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .Where(o => o.BuyerId == buyerId)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
            return Ok(orders);
        }

        // --- 4. QUÁN XÁC NHẬN ĐƠN (Bắt đầu chế biến) ---
        [HttpPut("shop-accept/{id}")]
        public async Task<IActionResult> ShopAcceptOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            // Chỉ quán mới có thể nhận khi đơn đã thanh toán hoặc là tiền mặt (Pending)
            order.Status = "Preparing";
            await _context.SaveChangesAsync();
            return Ok();
        }

        // --- 5. QUÁN BÁO ĐÃ NẤU XONG ---
        [HttpPut("shop-ready/{id}")]
        public async Task<IActionResult> ShopReadyOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            order.Status = "Ready";
            await _context.SaveChangesAsync();
            return Ok();
        }

        // --- 6. LẤY ĐƠN CHO SHIPPER (Chỉ hiện đơn đã sẵn sàng hoặc đang giao của chính mình) ---
        [HttpGet("available-for-shipper/{shipperId}")]
        public async Task<ActionResult<IEnumerable<Order>>> GetOrdersForShipper(int shipperId)
        {
            return await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o =>
                    ((o.Status == "Ready" || o.Status == "Confirmed" || o.Status == "Accepted") && o.ShipperId == null) ||
                    (o.Status == "Delivering" && o.ShipperId == shipperId)
                )
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
        }

        // --- 7. SHIPPER NHẬN ĐƠN (Có chặn giới hạn & giam tiền ví) ---
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] int shipperId)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            if (order.ShipperId != null && order.ShipperId != shipperId)
                return BadRequest(new { message = "Đơn hàng đã có người khác nhận." });

            if (order.Status != "Ready" && order.Status != "Confirmed" && order.Status != "Accepted")
                return BadRequest(new { message = "Đơn hàng chưa sẵn sàng để giao." });

            // KIỂM TRA GIỚI HẠN ĐƠN HÀNG TỪ SETTINGS
            var settings = await _context.SystemSettings.FirstOrDefaultAsync();
            int maxLimit = settings?.MaxOrderPerShipper ?? 3;

            var deliveringCount = await _context.Orders
                .CountAsync(o => o.ShipperId == shipperId && o.Status == "Delivering");

            if (deliveringCount >= maxLimit)
            {
                return BadRequest(new { message = $"Bạn đã đạt giới hạn nhận tối đa {maxLimit} đơn hàng cùng lúc." });
            }

            var shipper = await _context.Shippers.FindAsync(shipperId);
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);

            // Số tiền giam = Tiền món + phí ship
            decimal amountToHold = (decimal)(order.TotalAmount + order.ShippingFee);

            if (wallet == null || wallet.Balance < amountToHold)
                return BadRequest(new { message = "Số dư ví không đủ để nhận đơn thu hộ." });

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

        // --- 8. HOÀN THÀNH ĐƠN HÀNG (Chia tiền Quán & Shipper) ---
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == id);
            if (order == null || order.Status == "Completed") return Ok();

            order.Status = "Completed";
            order.DeliveredAt = DateTime.Now;

            decimal foodAmount = (decimal)order.TotalAmount;
            decimal systemFee = (decimal)order.ShippingFee;
            decimal shipperPay = 10000; // Công ship 10k

            // Trả tiền cho Quán
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

            // Trả lại tiền giam + Công cho Shipper
            if (order.ShipperId.HasValue)
            {
                var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                var sw = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                if (sw != null)
                {
                    decimal holdAmount = foodAmount + systemFee;
                    // Nếu khách trả tiền mặt (0) -> Shipper giữ tiền mặt khách đưa -> Chỉ cộng công 10k vào ví
                    // Nếu khách chuyển khoản (1) -> Shipper ko có tiền mặt -> Trả lại tiền đã giam + 10k công
                    decimal totalBack = (order.PaymentMethod == 0) ? shipperPay : (holdAmount + shipperPay);

                    sw.Balance += totalBack;
                    _context.Transactions.Add(new Transaction { WalletId = sw.Id, Amount = totalBack, Type = "SHIPPER_EARNING", Description = $"Hoàn vốn/Công đơn #{order.Id}", Status = 1, OrderId = order.Id, CreatedAt = DateTime.Now });
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Giao hàng thành công" });
        }

        // --- 9. CÁC HÀM THỐNG KÊ DOANH THU QUÁN ---
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
            return await _context.Orders
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .Where(o => o.ShopId == shopId)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
        }

        [HttpGet("shop-stats-detailed/{shopId}")]
        public async Task<ActionResult<DetailedShopStatsDto>> GetDetailedShopStats(int shopId, [FromQuery] string startDate, [FromQuery] string endDate)
        {
            try
            {
                DateTime start = DateTime.Parse(startDate).Date;
                DateTime end = DateTime.Parse(endDate).Date.AddDays(1).AddTicks(-1);

                var filtered = await _context.Orders
                    .Include(o => o.OrderItems)
                        .ThenInclude(oi => oi.Product)
                    .Where(o => o.ShopId == shopId && o.CreatedAt >= start && o.CreatedAt <= end)
                    .ToListAsync();

                var successOrders = filtered.Where(o => o.Status == "Completed").ToList();

                var productStats = successOrders
                    .SelectMany(o => o.OrderItems)
                    .GroupBy(oi => oi.Product.Name)
                    .Select(g => new ProductStatDTO
                    {
                        ProductName = g.Key,
                        TotalQuantity = g.Sum(oi => oi.Quantity),
                        TotalRevenue = (decimal)g.Sum(oi => (double)oi.UnitPrice * oi.Quantity)
                    })
                    .OrderByDescending(ps => ps.TotalQuantity)
                    .Take(10)
                    .ToList();

                return Ok(new DetailedShopStatsDto
                {
                    TotalOrders = filtered.Count,
                    SuccessOrders = successOrders.Count,
                    FailedOrders = filtered.Count(o => o.Status == "Cancelled" || o.Status == "Rejected"),
                    TotalRevenue = successOrders.Sum(o => (decimal)o.TotalAmount),
                    ProductStats = productStats
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi lấy thống kê: " + ex.Message });
            }
        }
    }
}