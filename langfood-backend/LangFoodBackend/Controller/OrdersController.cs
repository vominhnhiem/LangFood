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

        // 1. BUYER ĐẶT HÀNG
        [HttpPost]
        public async Task<ActionResult<Order>> PostOrder(Order order)
        {
            if (order == null) return BadRequest(new { message = "Dữ liệu trống!" });

            // KIỂM TRA SỰ TỒN TẠI CỦA CỬA HÀNG (Tránh lỗi Foreign Key)
            var shopExists = await _context.Shops.AnyAsync(s => s.Id == order.ShopId);
            if (!shopExists)
            {
                return BadRequest(new { 
                    success = false, 
                    message = "Cửa hàng không tồn tại hoặc đã ngừng hoạt động!" 
                });
            }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                order.CreatedAt = DateTime.Now;

                // Quy trình: Nếu là QR/Ví thì chờ Admin duyệt tiền, nếu Tiền mặt thì vào thẳng Shop
                if (order.PaymentMethod == 1) // Chuyển khoản/Ví
                {
                    order.Status = "PendingPayment";
                }
                else // Tiền mặt
                {
                    order.Status = "Confirmed"; // Chuyển thẳng cho Shop
                }

                // Xóa các object liên quan để EF không tạo mới dư thừa
                order.Buyer = null;
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
                await transaction.CommitAsync();

                return Ok(order);
            }
            catch (DbUpdateException ex)
            {
                await transaction.RollbackAsync();
                var innerError = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return BadRequest(new { 
                    success = false, 
                    message = "Lỗi lưu Database (Database Error)", 
                    details = innerError 
                });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { 
                    success = false, 
                    message = "Lỗi hệ thống (System Error)", 
                    details = ex.Message 
                });
            }
        }

        // 2. ADMIN DUYỆT TIỀN (Chỉ dành cho thanh toán chuyển khoản)
        [HttpPut("admin-approve/{id}")]
        public async Task<IActionResult> AdminApprove(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            if (order.Status != "PendingPayment")
                return BadRequest(new { message = "Đơn hàng này không ở trạng thái chờ duyệt tiền." });

            order.Status = "Confirmed"; // Sau khi duyệt, Shop mới thấy đơn
            await _context.SaveChangesAsync();

            return Ok(new { message = "Admin đã duyệt tiền thành công!" });
        }

        // 3. SHOP LẤY ĐƠN (Chỉ thấy đơn đã Admin duyệt hoặc đang làm)
        [HttpGet("shop/{shopId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetOrdersByShop(int shopId)
        {
            var orders = await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o => o.ShopId == shopId && (o.Status == "Confirmed" || o.Status == "Processing"))
                .OrderByDescending(o => o.CreatedAt)
                .Select(o => new {
                    o.Id,
                    o.BuyerName,
                    o.Status,
                    o.TotalAmount,
                    o.ShippingFee,
                    o.CreatedAt,
                    o.DeliveryBuilding,
                    o.DeliveryRoom,
                    OrderItems = o.OrderItems.Select(oi => new {
                        oi.Product.Name,
                        oi.Quantity,
                        oi.UnitPrice
                    })
                })
                .ToListAsync();
            return Ok(orders);
        }

        // 4. SHOP XÁC NHẬN NHẬN ĐƠN (Bắt đầu làm đồ ăn)
        [HttpPut("shop-accept/{id}")]
        public async Task<IActionResult> ShopAccept(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            order.Status = "Processing"; // Shop đang làm, lúc này Shipper mới thấy đơn
            await _context.SaveChangesAsync();
            return Ok(new { message = "Shop đã nhận đơn và đang chuẩn bị đồ ăn" });
        }

        // 5. SHIPPER LẤY ĐƠN ĐANG CHỜ (Status = Processing)
        [HttpGet("available")]
        public async Task<ActionResult<IEnumerable<Order>>> GetAvailableOrders()
        {
            return await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o => o.Status == "Processing" && o.ShipperId == null)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
        }

        // 6. SHIPPER NHẬN ĐƠN (Ký quỹ 25k và trừ tiền ví)
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] int shipperId)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var order = await _context.Orders.FindAsync(id);
                var shipper = await _context.Shippers.FindAsync(shipperId);
                if (order == null || shipper == null) return NotFound();

                if (order.ShipperId != null) return BadRequest(new { message = "Đơn đã có người nhận!" });

                // Logic ký quỹ: Shipper trả 25k cho Shop (tiền gốc món ăn)
                var shipperWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                decimal depositAmount = 25000; // Tiền vốn mặc định theo yêu cầu của bạn

                if (shipperWallet == null || shipperWallet.Balance < depositAmount)
                    return BadRequest(new { message = "Ví không đủ 25k để ký quỹ nhận đơn!" });

                // A. Trừ tiền Shipper
                shipperWallet.Balance -= depositAmount;
                _context.Transactions.Add(new Transaction
                {
                    WalletId = shipperWallet.Id,
                    Amount = -depositAmount,
                    Type = "DEPOSIT",
                    Description = $"Ký quỹ nhận đơn #{order.Id}",
                    CreatedAt = DateTime.Now
                });

                // B. Cộng tiền cho Shop (Shop nhận 25k luôn)
                var shop = await _context.Shops.FindAsync(order.ShopId);
                var shopWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shop.UserId);
                if (shopWallet != null)
                {
                    shopWallet.Balance += depositAmount;
                    _context.Transactions.Add(new Transaction
                    {
                        WalletId = shopWallet.Id,
                        Amount = depositAmount,
                        Type = "RECEIVE",
                        Description = $"Nhận tiền gốc đơn #{order.Id} từ Shipper",
                        CreatedAt = DateTime.Now
                    });
                }

                order.ShipperId = shipperId;
                order.Status = "Shipping";

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return Ok(new { message = "Nhận đơn và ký quỹ thành công!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi ký quỹ: " + ex.Message });
            }
        }

        // 7. HOÀN THÀNH ĐƠN (Shipper nhận lại 45k)
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();
            if (order.Status != "Shipping") return BadRequest("Đơn hàng chưa được giao.");

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                if (order.ShipperId.HasValue)
                {
                    var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                    var shipperWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);

                    if (shipperWallet != null)
                    {
                        // Shipper nhận: 25k vốn + 5k ship + 15k thưởng = 45k
                        decimal totalReward = 45000;
                        shipperWallet.Balance += totalReward;

                        _context.Transactions.Add(new Transaction
                        {
                            WalletId = shipperWallet.Id,
                            Amount = totalReward,
                            Type = "RECEIVE",
                            Description = $"Hoàn tiền vốn + Ship + Thưởng đơn #{order.Id}",
                            OrderId = order.Id,
                            CreatedAt = DateTime.Now
                        });
                    }
                }

                order.Status = "Completed";
                order.DeliveredAt = DateTime.Now;

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = "Giao hàng thành công. Shipper đã nhận đủ 45k!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi hoàn tất: " + ex.Message });
            }
        }
        // 9. LẤY THỐNG KÊ DOANH THU CHO SHOP
        [HttpGet("shop-stats/{shopId}")]
        public async Task<ActionResult> GetShopStats(int shopId)
        {
            var today = DateTime.Today;
            var firstDayOfMonth = new DateTime(today.Year, today.Month, 1);

            // Lấy tất cả đơn hàng của Shop để tính toán
            var shopOrders = await _context.Orders
                .Where(o => o.ShopId == shopId)
                .ToListAsync();

            // 1. Số đơn hàng được đặt trong hôm nay (tất cả trạng thái trừ Cancelled)
            var todayOrderCount = shopOrders
                .Count(o => o.CreatedAt.Date == today && o.Status != "Cancelled");

            // 2. Doanh thu hôm nay (Chỉ tính các đơn đã giao hoặc đang giao - vì lúc này shop đã nhận tiền gốc)
            var todayRevenue = shopOrders
                .Where(o => o.CreatedAt.Date == today && (o.Status == "Shipping" || o.Status == "Completed"))
                .Sum(o => o.TotalAmount);

            // 3. Doanh thu tháng này
            var monthRevenue = shopOrders
                .Where(o => o.CreatedAt >= firstDayOfMonth && (o.Status == "Shipping" || o.Status == "Completed"))
                .Sum(o => o.TotalAmount);

            // 4. Tổng số đơn hàng từ trước đến nay
            var totalOrders = shopOrders.Count(o => o.Status == "Completed");

            return Ok(new
            {
                TodayOrderCount = todayOrderCount,
                TodayRevenue = todayRevenue,
                MonthRevenue = monthRevenue,
                TotalOrders = totalOrders
            });
        }
        // 8. LẤY LỊCH SỬ ĐƠN HÀNG CỦA USER
        [HttpGet("buyer/{buyerId}")]
        public async Task<ActionResult<List<Order>>> GetOrdersByBuyer(string buyerId)
        {
            return await _context.Orders
                .Include(o => o.OrderItems)
                .Where(o => o.BuyerId == buyerId)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
        }
    }
}