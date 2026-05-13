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
                .FirstOrDefaultAsync(m => m.Id == id);

            if (order == null) return NotFound();
            return View(order);
        }

        // 3. XỬ LÝ HOÀN THÀNH ĐƠN HÀNG VÀ CHUYỂN TIỀN (FIXED)
        [HttpPost]
        public async Task<IActionResult> CompleteOrder(int id)
        {
            // Load Order kèm theo Shop để tránh lỗi Null Reference (CS8602)
            var order = await _context.Orders
                .Include(o => o.Shop)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null || order.Status == "COMPLETED")
                return BadRequest("Đơn hàng không tồn tại hoặc đã hoàn thành.");

            // A. Cập nhật trạng thái đơn hàng
            order.Status = "COMPLETED";
            order.DeliveredAt = DateTime.Now;

            // B. XỬ LÝ VÍ SHIPPER
            if (order.ShipperId.HasValue)
            {
                var shipper = await _context.Shippers.FindAsync(order.ShipperId.Value);
                if (shipper != null)
                {
                    var shipperWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shipper.UserId);
                    if (shipperWallet != null)
                    {
                        // Shipper nhận 45k (bao gồm vốn + ship + thưởng)
                        decimal totalReward = 45000; 
                        shipperWallet.Balance += totalReward;

                        _context.Transactions.Add(new Transaction
                        {
                            WalletId = shipperWallet.Id,
                            Amount = totalReward,
                            Type = "ORDER_REWARD",
                            Description = $"Hoàn vốn & Thưởng đơn #{order.Id}",
                            Status = 1,
                            OrderId = order.Id,
                            CreatedAt = DateTime.Now
                        });
                    }
                }
            }

            // C. XỬ LÝ VÍ SHOP
            if (order.Shop != null)
            {
                var shopWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == order.Shop.UserId);
                if (shopWallet != null)
                {
                    // FIX LỖI CS1061: Thay TotalPrice thành TotalAmount
                    // Tiền Shop nhận = Tổng đơn - Phí ship (hoặc theo logic riêng của bạn)
                    decimal foodPrice = order.TotalAmount - order.ShippingFee; 
                    
                    shopWallet.Balance += foodPrice;

                    _context.Transactions.Add(new Transaction
                    {
                        WalletId = shopWallet.Id,
                        Amount = foodPrice,
                        Type = "RECEIVE",
                        Description = $"Tiền bán món ăn đơn #{order.Id}",
                        Status = 1,
                        OrderId = order.Id,
                        CreatedAt = DateTime.Now
                    });
                }
            }

            // Lưu tất cả thay đổi vào Database
            await _context.SaveChangesAsync();

            TempData["Success"] = "Xác nhận hoàn thành đơn hàng và cộng tiền thành công!";
            return RedirectToAction(nameof(Index));
        }
    }
}