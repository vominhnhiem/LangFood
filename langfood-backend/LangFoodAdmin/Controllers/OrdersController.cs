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
            var buildings = await _context.Buildings.ToListAsync();
            ViewBag.BuildingList = new SelectList(buildings, "Id", "Name", buildingId);

            IQueryable<Order> query = _context.Orders
                .Include(o => o.Building)
                .Include(o => o.Shop)
                .OrderByDescending(o => o.CreatedAt);

            if (buildingId.HasValue)
            {
                query = query.Where(o => o.BuildingId == buildingId.Value);
            }

            var orders = await query.ToListAsync();
            return View(orders);
        }

        // 2. Chi tiết đơn hàng
        public async Task<IActionResult> Details(int id)
        {
            var order = await _context.Orders
                .Include(o => o.Building)
                .Include(o => o.Shop)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (order == null) return NotFound();
            return View(order);
        }

        // 3. XỬ LÝ ADMIN XÁC NHẬN HOÀN THÀNH ĐƠN (Thanh toán cho Shipper)
        [HttpPost]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            // Sử dụng Transaction để đảm bảo an toàn dữ liệu tiền tệ
            using var dbTransaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var order = await _context.Orders.FindAsync(id);

                if (order == null) return NotFound();

                // Chỉ cho phép hoàn thành các đơn đang giao (Shipping)
                if (order.Status == "Completed")
                    return BadRequest("Đơn hàng này đã được hoàn thành trước đó.");

                // A. Cập nhật trạng thái đơn hàng
                order.Status = "Completed";
                order.DeliveredAt = DateTime.Now;

                // B. XỬ LÝ VÍ SHIPPER (Trả 45k cho Shipper)
                if (order.ShipperId.HasValue)
                {
                    var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                    if (shipper != null)
                    {
                        var shipperWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                        if (shipperWallet != null)
                        {
                            // Theo logic: Shipper nhận 45k (25k vốn ký quỹ + 5k ship + 15k thưởng admin)
                            decimal totalReward = 45000;
                            shipperWallet.Balance += totalReward;
                            shipperWallet.UpdatedAt = DateTime.Now;

                            _context.Transactions.Add(new Transaction
                            {
                                WalletId = shipperWallet.Id,
                                Amount = totalReward,
                                Type = "RECEIVE",
                                Description = $"Hoàn vốn + Ship + Thưởng đơn #{order.Id}",
                                Status = 1, // Thành công
                                OrderId = order.Id,
                                CreatedAt = DateTime.Now
                            });
                        }
                    }
                }

                // C. LƯU Ý VỀ VÍ SHOP: 
                // Shop đã nhận 25k từ Shipper ngay lúc Shipper bấm "Nhận đơn" (Ký quỹ).
                // Do đó ở bước hoàn thành này Admin không cần cộng thêm tiền cho Shop nữa.

                await _context.SaveChangesAsync();
                await dbTransaction.CommitAsync();

                TempData["Success"] = $"Đơn hàng #{id} đã hoàn thành. Shipper đã nhận 45,000đ.";
            }
            catch (Exception ex)
            {
                await dbTransaction.RollbackAsync();
                TempData["Error"] = "Lỗi xử lý: " + ex.Message;
            }

            return RedirectToAction(nameof(Index));
        }

        // 4. Xóa đơn hàng (Nếu cần)
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