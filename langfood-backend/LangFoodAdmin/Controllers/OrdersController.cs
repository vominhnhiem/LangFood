using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using LangFood.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace LangFoodAdmin.Controllers
{
    public class OrdersController : Controller
    {
        private readonly LangFoodDbContext _context;

        public OrdersController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. Hiển thị danh sách đơn hàng có lọc theo tòa nhà
        public async Task<IActionResult> Index(int? buildingId)
        {
            try
            {
                var buildings = await _context.Buildings.AsNoTracking().ToListAsync();
                ViewBag.BuildingList = new SelectList(buildings, "Id", "Name", buildingId);

                IQueryable<Order> query = _context.Orders
                    .AsNoTracking()
                    .Include(o => o.Building)
                    .Include(o => o.Shop)
                    .OrderByDescending(o => o.CreatedAt);

                if (buildingId.HasValue)
                {
                    query = query.Where(o => o.BuildingId == buildingId.Value);
                }

                var orders = await query.Take(100).ToListAsync();
                return View(orders);
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Lỗi kết nối cơ sở dữ liệu: " + ex.Message;
                return View(new List<Order>());
            }
        }

        // 2. Chi tiết đơn hàng
        public async Task<IActionResult> Details(int id)
        {
            var order = await _context.Orders
                .AsNoTracking()
                .Include(o => o.Building)
                .Include(o => o.Shop)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (order == null) return NotFound();
            return View(order);
        }

        // --- CÁC HÀM XỬ LÝ TRẠNG THÁI ---

        // A. SHOP NHẬN ĐƠN (Paid -> Preparing)
        [HttpPost]
        public async Task<IActionResult> ShopAcceptOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null || order.Status != "Paid")
                return BadRequest("Đơn hàng không ở trạng thái chờ nhận hoặc không tồn tại.");

            order.Status = "Preparing";
            await _context.SaveChangesAsync();
            TempData["Success"] = $"Shop đã nhận đơn #{id}. Đang chuẩn bị món!";
            return RedirectToAction(nameof(Details), new { id = id });
        }

        // B. SHOP BÁO NẤU XONG (Preparing -> Ready)
        [HttpPost]
        public async Task<IActionResult> ShopReady(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order == null || order.Status != "Preparing")
                return BadRequest("Đơn hàng chưa được chuẩn bị.");

            order.Status = "Ready";
            await _context.SaveChangesAsync();
            TempData["Success"] = $"Đơn hàng #{id} đã nấu xong. Đang tìm Shipper!";
            return RedirectToAction(nameof(Details), new { id = id });
        }

        // C. SHIPPER NHẬN ĐƠN VÀ ĐẶT CỌC (Trừ tiền ví Shipper)
        [HttpPost]
        public async Task<IActionResult> ShipperPickUp(int id, string shipperUserId)
        {
            using var dbTransaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var order = await _context.Orders.FindAsync(id);
                var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipperUserId);

                if (order == null || order.Status != "Ready") return BadRequest("Đơn hàng không sẵn sàng.");
                if (wallet == null || wallet.Balance < order.TotalAmount)
                    return BadRequest("Ví không đủ tiền cọc món ăn!");

                // Logic trừ tiền cọc (Dùng TotalAmount từ Model của mày)
                wallet.Balance -= order.TotalAmount;
                order.Status = "Delivering";

                // Vì ShipperId trong Model của mày là int?, cần tìm Id của Shipper từ UserId
                var shipper = await _context.Shippers.FirstOrDefaultAsync(s => s.UserId == shipperUserId);
                if (shipper != null) order.ShipperId = shipper.Id;

                _context.Transactions.Add(new Transaction
                {
                    WalletId = wallet.Id,
                    Amount = -order.TotalAmount,
                    Type = "ORDER_DEPOSIT",
                    Description = $"Đặt cọc cho đơn hàng #{order.Id}",
                    Status = 1,
                    CreatedAt = DateTime.Now
                });

                await _context.SaveChangesAsync();
                await dbTransaction.CommitAsync();
                return Ok(new { message = "Shipper nhận đơn và đặt cọc thành công!" });
            }
            catch (Exception ex)
            {
                await dbTransaction.RollbackAsync();
                return BadRequest(ex.Message);
            }
        }

        // D. ADMIN XÁC NHẬN HOÀN THÀNH (Trả cọc + Ship + Thưởng)
        [HttpPost]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            using var dbTransaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var order = await _context.Orders.FindAsync(id);
                if (order == null) return NotFound();

                if (order.Status == "Completed") return BadRequest("Đơn hàng này đã hoàn thành.");

                order.Status = "Completed";
                order.DeliveredAt = DateTime.Now;

                if (order.ShipperId.HasValue)
                {
                    var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                    if (shipper != null)
                    {
                        var shipperWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                        if (shipperWallet != null)
                        {
                            // Logic: Hoàn vốn (TotalAmount) + Ship (5k) + Thưởng Admin (15k)
                            decimal shippingFee = 5000;
                            decimal adminBonus = 15000;
                            decimal totalReward = order.TotalAmount + shippingFee + adminBonus;

                            shipperWallet.Balance += totalReward;
                            shipperWallet.UpdatedAt = DateTime.Now;

                            _context.Transactions.Add(new Transaction
                            {
                                WalletId = shipperWallet.Id,
                                Amount = totalReward,
                                Type = "RECEIVE_REWARD",
                                Description = $"Hoàn cọc {order.TotalAmount} + Ship {shippingFee} + Thưởng {adminBonus} đơn #{order.Id}",
                                Status = 1,
                                OrderId = order.Id,
                                CreatedAt = DateTime.Now
                            });
                        }
                    }
                }

                await _context.SaveChangesAsync();
                await dbTransaction.CommitAsync();
                TempData["Success"] = $"Đơn hàng #{id} thành công. Shipper đã nhận tiền hoàn cọc và thưởng.";
            }
            catch (Exception ex)
            {
                await dbTransaction.RollbackAsync();
                TempData["Error"] = "Lỗi xử lý: " + ex.Message;
            }
            return RedirectToAction(nameof(Index));
        }

        // 4. Xóa đơn hàng
        [HttpPost]
        public async Task<IActionResult> DeleteOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order != null)
            {
                _context.Orders.Remove(order);
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }
    }
}