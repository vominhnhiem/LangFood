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

        // 1. Lấy thống kê chi tiết cho Quán ăn (Bao gồm biểu đồ Top món ăn)
        [HttpGet("shop-stats-detailed/{shopId}")]
        public async Task<ActionResult<DetailedShopStatsDto>> GetDetailedShopStats(
            int shopId,
            [FromQuery] string startDate,
            [FromQuery] string endDate)
        {
            DateTime start = DateTime.Parse(startDate).Date;
            DateTime end = DateTime.Parse(endDate).Date.AddDays(1).AddTicks(-1);
            DateTime now = DateTime.Now;

            var stats = new DetailedShopStatsDto();

            var allShopOrders = await _context.Orders
                .Where(o => o.ShopId == shopId)
                .ToListAsync();

            stats.TodayOrderCount = allShopOrders.Count(o => o.CreatedAt.Date == now.Date);
            stats.TodayRevenue = allShopOrders
                .Where(o => o.CreatedAt.Date == now.Date && o.Status == "Completed")
                .Sum(o => (decimal)o.TotalAmount);

            stats.MonthRevenue = allShopOrders
                .Where(o => o.CreatedAt.Month == now.Month && o.CreatedAt.Year == now.Year && o.Status == "Completed")
                .Sum(o => (decimal)o.TotalAmount);

            var filteredOrders = allShopOrders
                .Where(o => o.CreatedAt >= start && o.CreatedAt <= end)
                .ToList();

            stats.TotalOrders = filteredOrders.Count;
            stats.SuccessOrders = filteredOrders.Count(o => o.Status == "Completed");
            stats.FailedOrders = filteredOrders.Count(o => o.Status == "Cancelled" || o.Status == "Rejected");
            stats.TotalRevenue = filteredOrders
                .Where(o => o.Status == "Completed")
                .Sum(o => (decimal)o.TotalAmount);

            stats.ProductStats = await _context.OrderItems
                .Include(oi => oi.Product)
                .Where(oi => oi.Order.ShopId == shopId &&
                             oi.Order.Status == "Completed" &&
                             oi.Order.CreatedAt >= start &&
                             oi.Order.CreatedAt <= end)
                .GroupBy(oi => oi.Product.Name)
                .Select(g => new ProductStatDTO
                {
                    ProductName = g.Key,
                    TotalQuantity = g.Sum(x => x.Quantity),
                    TotalRevenue = (decimal)g.Sum(x => x.Quantity * x.UnitPrice)
                })
                .OrderByDescending(x => x.TotalQuantity)
                .Take(5)
                .ToListAsync();

            return Ok(stats);
        }

        // 2. HOÀN THÀNH ĐƠN HÀNG - XỬ LÝ LOGIC TIỀN TỆ THEO YÊU CẦU (CHỐT TIỀN)
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FirstOrDefaultAsync(o => o.Id == id);
            if (order == null) return NotFound();
            if (order.Status == "Completed") return Ok(new { message = "Đơn hàng đã hoàn thành từ trước." });

            order.Status = "Completed";
            order.DeliveredAt = DateTime.Now; // FIX LỖI: Gán trực tiếp DateTime thay vì string

            // CẤU HÌNH PHÍ ĐỒNG BỘ VỚI ANDROID
            decimal shipperPay = 10000; // Tiền công hệ thống trả cho Shipper (10k)
            decimal foodAmount = (decimal)order.TotalAmount; // Tiền cơm (ví dụ 25k)

            // --- A. XỬ LÝ VÍ QUÁN ĂN (Luôn nhận được tiền món ăn) ---
            var shop = await _context.Shops.FindAsync(order.ShopId);
            if (shop != null)
            {
                var shopWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shop.UserId);
                if (shopWallet != null)
                {
                    shopWallet.Balance += foodAmount;
                    shopWallet.UpdatedAt = DateTime.Now;
                    _context.Transactions.Add(new Transaction
                    {
                        WalletId = shopWallet.Id,
                        Amount = foodAmount,
                        Type = "ORDER_REVENUE",
                        Description = $"Doanh thu món ăn đơn hàng #{order.Id}",
                        Status = 1,
                        OrderId = order.Id,
                        CreatedAt = DateTime.Now
                    });
                }
            }

            // --- B. XỬ LÝ VÍ SHIPPER ---
            if (order.ShipperId.HasValue)
            {
                var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                if (shipper != null)
                {
                    var shipperWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                    if (shipperWallet != null)
                    {
                        if (order.PaymentMethod == 0) // THANH TOÁN TIỀN MẶT (COD)
                        {
                            // 1. Shipper đã cầm tiền mặt từ khách (Cơm + Phí hệ thống, ví dụ 25k + 3k = 28k)
                            // => Hệ thống TRỪ NỢ Shipper số tiền này để trả cho quán và admin
                            decimal amountToDebit = foodAmount + (decimal)order.ShippingFee;
                            shipperWallet.Balance -= amountToDebit;

                            _context.Transactions.Add(new Transaction
                            {
                                WalletId = shipperWallet.Id,
                                Amount = -amountToDebit,
                                Type = "COD_COLLECTED",
                                Description = $"Thu hồi tiền mặt đơn #{order.Id} (Cơm + Phí hệ thống)",
                                Status = 1,
                                OrderId = order.Id,
                                CreatedAt = DateTime.Now
                            });
                        }

                        // 2. CỘNG TIỀN CÔNG SHIP (Shipper nhận được 10k công vào ví)
                        shipperWallet.Balance += shipperPay;
                        _context.Transactions.Add(new Transaction
                        {
                            WalletId = shipperWallet.Id,
                            Amount = shipperPay,
                            Type = "SHIPPER_EARNING",
                            Description = $"Tiền công giao hàng đơn #{order.Id}",
                            Status = 1,
                            OrderId = order.Id,
                            CreatedAt = DateTime.Now
                        });

                        shipperWallet.UpdatedAt = DateTime.Now;
                    }
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Giao hàng thành công. Tiền đã được chia về các ví." });
        }

        // 3. Các API hỗ trợ khác
        [HttpPut("shop-accept/{id}")]
        public async Task<IActionResult> ShopAcceptOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            order.Status = "Accepted";
            await _context.SaveChangesAsync();
            return Ok();
        }

        [HttpPut("shop-ready/{id}")]
        public async Task<IActionResult> ShopReadyOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            order.Status = "Ready";
            await _context.SaveChangesAsync();
            return Ok();
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
    }
}