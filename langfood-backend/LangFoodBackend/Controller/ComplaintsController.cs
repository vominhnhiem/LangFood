using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;

namespace LangFoodBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ComplaintsController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public ComplaintsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // --- 1. GỬI KHIẾU NẠI ĐƠN HÀNG (Sinh viên) ---
        [HttpPost]
        public async Task<IActionResult> CreateComplaint([FromForm] int orderId, [FromForm] string reason, [FromForm] string detail, IFormFile? imageProof)
        {
            var order = await _context.Orders.FindAsync(orderId);
            if (order == null)
                return NotFound(new { message = "Đơn hàng không tồn tại." });

            string? imageUrl = null;
            if (imageProof != null && imageProof.Length > 0)
            {
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "complaints");
                if (!Directory.Exists(uploadsFolder)) 
                    Directory.CreateDirectory(uploadsFolder);

                var uniqueFileName = Guid.NewGuid().ToString() + "_" + imageProof.FileName;
                var filePath = Path.Combine(uploadsFolder, uniqueFileName);

                using (var fileStream = new FileStream(filePath, FileMode.Create))
                {
                    await imageProof.CopyToAsync(fileStream);
                }
                imageUrl = "/images/complaints/" + uniqueFileName;
            }

            var complaint = new Complaint
            {
                OrderId = orderId,
                Reason = reason,
                Detail = detail,
                ImageProof = imageUrl,
                Status = 0, // Pending
                CreatedAt = DateTime.Now
            };

            _context.Complaints.Add(complaint);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Gửi khiếu nại thành công! Admin sẽ phản hồi sớm nhất.", complaintId = complaint.Id });
        }

        // --- 2. LẤY DANH SÁCH KHIẾU NẠI (Admin lọc) ---
        [HttpGet]
        public async Task<IActionResult> GetComplaints([FromQuery] int? buildingId, [FromQuery] int? shopId, [FromQuery] int? status)
        {
            var query = _context.Complaints
                .Include(c => c.Order)
                    .ThenInclude(o => o.Shop)
                .Include(c => c.Order)
                    .ThenInclude(o => o.Buyer)
                .AsQueryable();

            if (buildingId.HasValue)
            {
                // Lọc theo Tòa nhà của Buyer
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

            var result = await query
                .OrderByDescending(c => c.CreatedAt)
                .Select(c => new {
                    c.Id,
                    c.OrderId,
                    c.Reason,
                    c.Detail,
                    c.ImageProof,
                    c.Status,
                    c.AdminReply,
                    c.PenaltyAmount,
                    c.CreatedAt,
                    c.ResolvedAt,
                    ShopName = c.Order.Shop.Name,
                    BuyerName = c.Order.Buyer.FullName,
                    BuildingName = c.Order.DeliveryBuilding,
                    Room = c.Order.DeliveryRoom,
                    TotalAmount = c.Order.TotalAmount
                })
                .ToListAsync();

            return Ok(result);
        }

        // --- 3. XỬ LÝ KHIẾU NẠI & PHẠT (Admin) ---
        [HttpPost("resolve/{complaintId}")]
        public async Task<IActionResult> ResolveComplaint(int complaintId, [FromForm] string adminReply, [FromForm] decimal penaltyAmount)
        {
            var complaint = await _context.Complaints
                .Include(c => c.Order)
                .FirstOrDefaultAsync(c => c.Id == complaintId);

            if (complaint == null)
                return NotFound(new { message = "Không tìm thấy khiếu nại." });

            if (complaint.Status != 0)
                return BadRequest(new { message = "Khiếu nại này đã được xử lý rồi." });

            var order = complaint.Order;
            if (order == null)
                return NotFound(new { message = "Không tìm thấy đơn hàng liên kết." });

            // Tìm ví Quán (Seller) và ví Sinh viên (Buyer)
            var shop = await _context.Shops.FindAsync(order.ShopId);
            if (shop == null)
                return NotFound(new { message = "Không tìm thấy cửa hàng liên kết." });

            // BẮT BUỘC dùng Transaction
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

                        if (shopWallet == null)
                            return BadRequest(new { message = "Cửa hàng không có ví điện tử." });

                        if (buyerWallet == null)
                            return BadRequest(new { message = "Khách hàng không có ví điện tử." });

                        // 1. Trừ tiền quán
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

                        // 2. Hoàn tiền khách
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
                        Type = 2, // Refund/Joy
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
                        Type = 1, // Penalty/Sad
                        CreatedAt = DateTime.Now
                    };
                    _context.Notifications.Add(sellerNotif);

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new { message = "Xử lý khiếu nại thành công!" });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new { message = "Lỗi xử lý giao dịch: " + ex.Message });
                }
            }
        }

        // --- 3.5 LẤY CHI TIẾT KHIẾU NẠI THEO MÃ ĐƠN HÀNG ---
        [HttpGet("by-order/{orderId}")]
        public async Task<IActionResult> GetComplaintByOrderId(int orderId)
        {
            var complaint = await _context.Complaints
                .OrderByDescending(c => c.CreatedAt)
                .FirstOrDefaultAsync(c => c.OrderId == orderId);

            if (complaint == null)
                return NotFound(new { message = "Không tìm thấy khiếu nại cho đơn hàng này." });

            return Ok(complaint);
        }

        // --- 4. LẤY DANH SÁCH THÔNG BÁO (User/Seller) ---
        [HttpGet("notifications/{userId}")]
        public async Task<IActionResult> GetNotifications(string userId)
        {
            userId = userId.Replace("\"", "");
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();

            return Ok(notifications);
        }

        // --- 5. ĐÁNH DẤU ĐÃ ĐỌC THÔNG BÁO ---
        [HttpPost("notifications/read/{id}")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var notif = await _context.Notifications.FindAsync(id);
            if (notif == null) return NotFound();

            notif.IsRead = true;
            await _context.SaveChangesAsync();

            return Ok();
        }

        // --- 6. ĐẾM SỐ THÔNG BÁO CHƯA ĐỌC ---
        [HttpGet("/api/notifications/unread-count")]
        public async Task<IActionResult> GetUnreadCount([FromQuery] string userId)
        {
            userId = userId.Replace("\"", "");
            var count = await _context.Notifications
                .CountAsync(n => n.UserId == userId && !n.IsRead);
            return Ok(count);
        }

        // --- 7. ĐÁNH DẤU ĐÃ ĐỌC TẤT CẢ THÔNG BÁO ---
        [HttpPost("/api/notifications/mark-all-read")]
        public async Task<IActionResult> MarkAllRead([FromQuery] string userId)
        {
            userId = userId.Replace("\"", "");
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            foreach (var notif in notifications)
            {
                notif.IsRead = true;
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã đánh dấu đọc tất cả thông báo." });
        }

        // --- 8. LẤY THỐNG KÊ CHỜ DUYỆT (ADMIN) ---
        [HttpGet("/api/admin/pending-stats")]
        public async Task<IActionResult> GetPendingStats()
        {
            var complaintsCount = await _context.Complaints.CountAsync(c => c.Status == 0);
            var shopsCount = await _context.RoleRequests.CountAsync(r => r.RequestType == 1 && r.Status == 0);
            return Ok(new { pendingComplaints = complaintsCount, pendingShops = shopsCount });
        }
    }
}
