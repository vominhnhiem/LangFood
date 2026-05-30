using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;

namespace LangFoodAdmin.Controllers
{
    public class ComplaintsController : Controller
    {
        private readonly LangFoodDbContext _context;

        public ComplaintsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // --- 1. TRANG DANH SÁCH KHIẾU NẠI (CÓ BỘ LỌC) ---
        public async Task<IActionResult> Index(int? buildingId, int? shopId, int? status)
        {
            var query = _context.Complaints
                .Include(c => c.Order)
                    .ThenInclude(o => o.Shop)
                .Include(c => c.Order)
                    .ThenInclude(o => o.Buyer)
                .AsQueryable();

            if (buildingId.HasValue)
            {
                query = query.Where(c => c.Order.Buyer.BuildingId == buildingId.Value);
            }

            if (shopId.HasValue)
            {
                query = query.Where(c => c.Order.ShopId == shopId.Value);
            }

            if (status.HasValue)
            {
                query = query.Where(c => c.Status == status.Value);
            }

            ViewBag.Buildings = await _context.Buildings.ToListAsync();
            ViewBag.Shops = await _context.Shops.ToListAsync();
            ViewBag.SelectedBuildingId = buildingId;
            ViewBag.SelectedShopId = shopId;
            ViewBag.SelectedStatus = status;

            var complaints = await query
                .OrderByDescending(c => c.CreatedAt)
                .ToListAsync();

            return View(complaints);
        }

        // --- 2. XỬ LÝ KHIẾU NẠI (GỌI QUA AJAX) ---
        [HttpPost]
        public async Task<IActionResult> Resolve(int complaintId, string adminReply, decimal penaltyAmount)
        {
            var complaint = await _context.Complaints
                .Include(c => c.Order)
                .FirstOrDefaultAsync(c => c.Id == complaintId);

            if (complaint == null)
                return Json(new { success = false, message = "Không tìm thấy khiếu nại." });

            if (complaint.Status != 0)
                return Json(new { success = false, message = "Khiếu nại này đã được xử lý." });

            var order = complaint.Order;
            if (order == null)
                return Json(new { success = false, message = "Không tìm thấy đơn hàng liên quan." });

            var shop = await _context.Shops.FindAsync(order.ShopId);
            if (shop == null)
                return Json(new { success = false, message = "Không tìm thấy cửa hàng." });

            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    complaint.Status = 1; // Resolved
                    complaint.AdminReply = adminReply;
                    complaint.PenaltyAmount = penaltyAmount;
                    complaint.ResolvedAt = DateTime.Now;

                    if (penaltyAmount > 0)
                    {
                        var shopWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == shop.UserId);
                        var buyerWallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == order.BuyerId);

                        if (shopWallet == null || buyerWallet == null)
                        {
                            return Json(new { success = false, message = "Lỗi: Không tìm thấy tài khoản ví tương ứng." });
                        }

                        // 1. Khấu trừ tiền quán
                        shopWallet.Balance -= penaltyAmount;
                        _context.Transactions.Add(new Transaction
                        {
                            WalletId = shopWallet.Id,
                            Amount = -penaltyAmount,
                            Type = "PENALTY",
                            Description = $"Phạt vi phạm đơn hàng #{order.Id} - Lý do: {complaint.Reason}",
                            Status = 1,
                            OrderId = order.Id,
                            CreatedAt = DateTime.Now
                        });

                        // 2. Hoàn trả tiền cho khách
                        buyerWallet.Balance += penaltyAmount;
                        _context.Transactions.Add(new Transaction
                        {
                            WalletId = buyerWallet.Id,
                            Amount = penaltyAmount,
                            Type = "REFUND",
                            Description = $"Hoàn tiền khiếu nại đơn hàng #{order.Id}",
                            Status = 1,
                            OrderId = order.Id,
                            CreatedAt = DateTime.Now
                        });
                    }

                    // 3. Tạo thông báo cho Sinh viên (Buyer)
                    var buyerNotif = new Notification
                    {
                        UserId = order.BuyerId,
                        Title = "Kết quả khiếu nại đơn hàng #" + order.Id,
                        Content = penaltyAmount > 0 
                            ? $"Khiếu nại được chấp thuận. Bạn được hoàn {penaltyAmount:N0}đ vào ví. Phản hồi: {adminReply}"
                            : $"Khiếu nại đã được xử lý. Phản hồi từ Admin: {adminReply}",
                        Type = 2, // Refund
                        CreatedAt = DateTime.Now
                    };
                    _context.Notifications.Add(buyerNotif);

                    // 4. Tạo thông báo cho Quán (Seller)
                    var sellerNotif = new Notification
                    {
                        UserId = shop.UserId,
                        Title = "Thông báo xử phạt đơn hàng #" + order.Id,
                        Content = penaltyAmount > 0
                            ? $"Cửa hàng của bạn bị phạt khấu trừ {penaltyAmount:N0}đ do vi phạm ở đơn hàng #{order.Id}. Phản hồi: {adminReply}"
                            : $"Khiếu nại của khách hàng ở đơn #{order.Id} đã được xử lý. Phản hồi: {adminReply}",
                        Type = 1, // Penalty
                        CreatedAt = DateTime.Now
                    };
                    _context.Notifications.Add(sellerNotif);

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Json(new { success = true, message = "Xử lý khiếu nại và chuyển tiền thành công!" });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return Json(new { success = false, message = "Lỗi xử lý giao dịch: " + ex.Message });
                }
            }
        }

        // --- 3. LẤY THỐNG KÊ CHỜ DUYỆT CHO SIDEBAR BADGES ---
        [HttpGet("/api/admin/pending-stats")]
        public async Task<IActionResult> GetPendingStats()
        {
            var complaintsCount = await _context.Complaints.CountAsync(c => c.Status == 0);
            var shopsCount = await _context.RoleRequests.CountAsync(r => r.RequestType == 1 && r.Status == 0);
            return Json(new { pendingComplaints = complaintsCount, pendingShops = shopsCount });
        }
    }
}
