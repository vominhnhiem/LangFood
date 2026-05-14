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

            // KIỂM TRA SỰ TỒN TẠI CỦA CỬA HÀNG
            var shopExists = await _context.Shops.AnyAsync(s => s.Id == order.ShopId);
            if (!shopExists)
            {
                return BadRequest(new { success = false, message = "Cửa hàng không tồn tại!" });
            }

            using var dbTransaction = await _context.Database.BeginTransactionAsync();
            try
            {
                order.CreatedAt = DateTime.Now;

                // Thiết lập trạng thái ban đầu
                if (order.PaymentMethod == 1) // Chuyển khoản/QR
                {
                    order.Status = "PendingPayment";
                }
                else // Tiền mặt
                {
                    order.Status = "Confirmed"; // Tiền mặt thì Shop thấy luôn
                }

                // Xóa các object điều hướng để EF không tạo mới dữ liệu trùng
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
                await _context.SaveChangesAsync(); // Lưu đơn để lấy Id

                // --- XỬ LÝ TẠO GIAO DỊCH CHỜ DUYỆT (Để Admin thấy trên Web) ---
                if (order.PaymentMethod == 1)
                {
                    var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == order.BuyerId);

                    // NẾU CHƯA CÓ VÍ THÌ TẠO MỚI LUÔN
                    if (wallet == null)
                    {
                        wallet = new Wallet { UserId = order.BuyerId, Balance = 0, UpdatedAt = DateTime.Now };
                        _context.Wallets.Add(wallet);
                        await _context.SaveChangesAsync();
                    }

                    var pendingTrans = new Transaction
                    {
                        WalletId = wallet.Id,
                        Amount = order.TotalAmount + order.ShippingFee,
                        Type = "DEPOSIT", // Loại nạp tiền để khớp với trang duyệt của Admin
                        Status = 0,       // Trạng thái Chờ duyệt (Admin sẽ bấm nút duyệt trên web)
                        Description = $"Thanh toán đơn hàng #{order.Id} qua QR",
                        OrderId = order.Id,
                        CreatedAt = DateTime.Now
                    };
                    _context.Transactions.Add(pendingTrans);
                    await _context.SaveChangesAsync();
                }

                await dbTransaction.CommitAsync();
                return Ok(order);
            }
            catch (Exception ex)
            {
                await dbTransaction.RollbackAsync();
                return StatusCode(500, new { success = false, message = "Lỗi hệ thống", details = ex.Message });
            }
        }

        // 2. ADMIN DUYỆT TIỀN (Sử dụng khi Admin thao tác trực tiếp trên đơn hàng)
        [HttpPut("admin-approve/{id}")]
        public async Task<IActionResult> AdminApprove(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            if (order.Status != "PendingPayment")
                return BadRequest(new { message = "Đơn hàng này không ở trạng thái chờ duyệt tiền." });

            order.Status = "Confirmed";
            await _context.SaveChangesAsync();

            return Ok(new { message = "Admin đã duyệt tiền thành công!" });
        }

        // 3. SHOP LẤY ĐƠN (Chỉ thấy đơn đã duyệt hoặc đang làm)
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

            order.Status = "Processing";
            await _context.SaveChangesAsync();
            return Ok(new { message = "Shop đang chuẩn bị món ăn" });
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

        // 6. SHIPPER NHẬN ĐƠN (Ký quỹ 25k)
        [HttpPut("accept/{id}")]
        public async Task<IActionResult> AcceptOrder(int id, [FromQuery] int shipperId)
        {
            using var dbTransaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var order = await _context.Orders.FindAsync(id);
                var shipper = await _context.Shippers.FindAsync(shipperId);
                if (order == null || shipper == null) return NotFound();

                if (order.ShipperId != null) return BadRequest(new { message = "Đã có người nhận!" });

                var shipperWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                decimal depositAmount = 25000;

                if (shipperWallet == null || shipperWallet.Balance < depositAmount)
                    return BadRequest(new { message = "Ví không đủ 25k ký quỹ!" });

                // Trừ tiền Shipper
                shipperWallet.Balance -= depositAmount;
                _context.Transactions.Add(new Transaction
                {
                    WalletId = shipperWallet.Id,
                    Amount = -depositAmount,
                    Type = "DEPOSIT",
                    Status = 1, // Ký quỹ thành công ngay
                    Description = $"Ký quỹ nhận đơn #{order.Id}",
                    CreatedAt = DateTime.Now
                });

                // Cộng tiền cho Shop
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
                        Status = 1,
                        Description = $"Nhận tiền gốc đơn #{order.Id} từ Shipper",
                        CreatedAt = DateTime.Now
                    });
                }

                order.ShipperId = shipperId;
                order.Status = "Shipping";

                await _context.SaveChangesAsync();
                await dbTransaction.CommitAsync();
                return Ok(new { message = "Nhận đơn thành công!" });
            }
            catch (Exception ex)
            {
                await dbTransaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
        }

        // 7. HOÀN THÀNH ĐƠN (Shipper nhận 45k)
        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null) return NotFound();

            using var dbTransaction = await _context.Database.BeginTransactionAsync();
            try
            {
                if (order.ShipperId.HasValue)
                {
                    var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                    var shipperWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);

                    if (shipperWallet != null)
                    {
                        decimal totalReward = 45000;
                        shipperWallet.Balance += totalReward;

                        _context.Transactions.Add(new Transaction
                        {
                            WalletId = shipperWallet.Id,
                            Amount = totalReward,
                            Type = "RECEIVE",
                            Status = 1,
                            Description = $"Thanh toán công giao đơn #{order.Id}",
                            OrderId = order.Id,
                            CreatedAt = DateTime.Now
                        });
                    }
                }

                order.Status = "Completed";
                order.DeliveredAt = DateTime.Now;

                await _context.SaveChangesAsync();
                await dbTransaction.CommitAsync();
                return Ok(new { message = "Giao hàng thành công!" });
            }
            catch (Exception ex)
            {
                await dbTransaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
        }

        // 8. THỐNG KÊ DOANH THU SHOP
        [HttpGet("shop-stats/{shopId}")]
        public async Task<ActionResult> GetShopStats(int shopId)
        {
            var today = DateTime.Today;
            var shopOrders = await _context.Orders.Where(o => o.ShopId == shopId).ToListAsync();

            var todayOrderCount = shopOrders.Count(o => o.CreatedAt.Date == today && o.Status != "Cancelled");
            var todayRevenue = shopOrders.Where(o => o.CreatedAt.Date == today && (o.Status == "Shipping" || o.Status == "Completed")).Sum(o => o.TotalAmount);
            var monthRevenue = shopOrders.Where(o => o.CreatedAt.Month == today.Month && (o.Status == "Shipping" || o.Status == "Completed")).Sum(o => o.TotalAmount);
            var totalOrders = shopOrders.Count(o => o.Status == "Completed");

            return Ok(new
            {
                TodayOrderCount = todayOrderCount,
                TodayRevenue = todayRevenue,
                MonthRevenue = monthRevenue,
                TotalOrders = totalOrders
            });
        }

        // 9. LỊCH SỬ MUA HÀNG
        [HttpGet("buyer/{buyerId}")]
        public async Task<ActionResult<List<Order>>> GetOrdersByBuyer(string buyerId)
        {
            return await _context.Orders
                .Include(o => o.OrderItems).ThenInclude(oi => oi.Product)
                .Where(o => o.BuyerId == buyerId)
                .OrderByDescending(o => o.CreatedAt)
                .ToListAsync();
        }
    }
}