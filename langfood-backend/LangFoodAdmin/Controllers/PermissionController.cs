using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace LangFoodAdmin.Controllers
{
    public class PermissionController : Controller
    {
        private readonly LangFoodDbContext _context;

        public PermissionController(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            // Lấy danh sách các tài khoản Admin (RoleId = 0)
            var admins = await _context.Users
                .Where(u => u.RoleId == 0)
                .ToListAsync();

            return View(admins);
        }

        [HttpPost]
        public async Task<IActionResult> CreateAdmin(string fullName, string email, string password)
        {
            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password) || string.IsNullOrWhiteSpace(fullName))
            {
                return Json(new { success = false, message = "Vui lòng nhập đầy đủ thông tin!" });
            }

            // Kiểm tra xem Email đã tồn tại chưa
            var emailExists = await _context.Users.AnyAsync(u => u.Email == email);
            if (emailExists)
            {
                return Json(new { success = false, message = "Email này đã được đăng ký trong hệ thống!" });
            }

            // Sử dụng email làm Username (hoặc phần trước dấu @)
            var username = email.Split('@')[0];
            var usernameExists = await _context.Users.AnyAsync(u => u.Username == username);
            if (usernameExists)
            {
                // Thêm hậu tố ngẫu nhiên nếu username trùng
                username += new Random().Next(100, 999).ToString();
            }

            // Băm mật khẩu bằng SHA256 (mã hóa mật khẩu)
            var passwordHash = HashPassword(password);

            var newAdmin = new User
            {
                Id = Guid.NewGuid().ToString(),
                Username = username,
                Email = email,
                FullName = fullName,
                PasswordHash = passwordHash,
                RoleId = 0, // Admin role
                IsApproved = false, // Chờ duyệt
                CanManageOrders = false,
                CanManageFinance = false,
                CanManageShops = false
            };

            // Tạo ví cho Admin
            var wallet = new Wallet
            {
                UserId = newAdmin.Id,
                Balance = 0,
                UpdatedAt = DateTime.Now
            };

            _context.Users.Add(newAdmin);
            _context.Wallets.Add(wallet);
            
            // Ghi log hệ thống
            var log = new SystemLog
            {
                Content = $"Đăng ký tài khoản Admin mới: {fullName} ({email}) - Trạng thái: Chờ duyệt.",
                LogType = LogType.System,
                CreatedAt = DateTime.Now
            };
            _context.SystemLogs.Add(log);

            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Đăng ký tài khoản Admin mới thành công! Vui lòng chờ Super Admin phê duyệt." });
        }

        [HttpPost]
        public async Task<IActionResult> ApproveAdmin(string userId)
        {
            var admin = await _context.Users.FindAsync(userId);
            if (admin == null || admin.RoleId != 0)
            {
                return Json(new { success = false, message = "Không tìm thấy tài khoản Admin!" });
            }

            admin.IsApproved = true;

            // Ghi log hệ thống
            var log = new SystemLog
            {
                Content = $"Tài khoản Admin {admin.FullName} ({admin.Email}) đã được phê duyệt hoạt động.",
                LogType = LogType.System,
                CreatedAt = DateTime.Now
            };
            _context.SystemLogs.Add(log);

            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Phê duyệt tài khoản Admin thành công!" });
        }

        [HttpPost]
        public async Task<IActionResult> UpdatePermissions(string userId, bool canManageOrders, bool canManageFinance, bool canManageShops)
        {
            var admin = await _context.Users.FindAsync(userId);
            if (admin == null || admin.RoleId != 0)
            {
                return Json(new { success = false, message = "Không tìm thấy tài khoản Admin!" });
            }

            admin.CanManageOrders = canManageOrders;
            admin.CanManageFinance = canManageFinance;
            admin.CanManageShops = canManageShops;

            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Cập nhật quyền thành công!" });
        }

        private string HashPassword(string password)
        {
            using (var sha256 = SHA256.Create())
            {
                var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                return Convert.ToHexString(bytes).ToLower();
            }
        }
    }
}
