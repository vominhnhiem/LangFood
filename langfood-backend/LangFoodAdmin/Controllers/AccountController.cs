using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace LangFoodAdmin.Controllers
{
    [AllowAnonymous]
    public class AccountController : Controller
    {
        private readonly LangFoodDbContext _context;

        public AccountController(LangFoodDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public IActionResult Login()
        {
            if (User.Identity != null && User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(string email, string password)
        {
            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            {
                ViewBag.Error = "Vui lòng nhập đầy đủ email và mật khẩu!";
                return View();
            }

            var passwordHash = HashPassword(password);

            // Tìm user có RoleId = 0 (Admin) và khớp Email hoặc Username
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.RoleId == 0 && (u.Email == email || u.Username == email) && u.PasswordHash == passwordHash);

            if (user == null)
            {
                ViewBag.Error = "Email hoặc mật khẩu không chính xác!";
                return View();
            }

            // Kiểm tra xem đã được phê duyệt chưa
            if (!user.IsApproved)
            {
                ViewBag.Error = "Tài khoản của bạn đang chờ Admin tổng phê duyệt. Vui lòng quay lại sau!";
                return View();
            }

            // Tạo claims đăng nhập
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.FullName ?? user.Username),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim(ClaimTypes.Role, "Admin"),
                new Claim("CanManageOrders", user.CanManageOrders.ToString()),
                new Claim("CanManageFinance", user.CanManageFinance.ToString()),
                new Claim("CanManageShops", user.CanManageShops.ToString())
            };

            var claimsIdentity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
            var authProperties = new AuthenticationProperties
            {
                IsPersistent = true,
                ExpiresUtc = DateTimeOffset.UtcNow.AddHours(2)
            };

            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(claimsIdentity), authProperties);

            // Ghi nhận nhật ký hệ thống
            var log = new SystemLog
            {
                Content = $"Admin {user.FullName} ({user.Email}) đã đăng nhập vào hệ thống.",
                LogType = LogType.System,
                CreatedAt = DateTime.Now
            };
            _context.SystemLogs.Add(log);
            await _context.SaveChangesAsync();

            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public IActionResult Register()
        {
            if (User.Identity != null && User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Register(string fullName, string email, string password, string confirmPassword)
        {
            if (string.IsNullOrWhiteSpace(fullName) || string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            {
                ViewBag.Error = "Vui lòng điền đầy đủ tất cả thông tin!";
                return View();
            }

            if (password != confirmPassword)
            {
                ViewBag.Error = "Mật khẩu xác nhận không khớp!";
                return View();
            }

            // Kiểm tra Email đã tồn tại chưa
            var emailExists = await _context.Users.AnyAsync(u => u.Email == email);
            if (emailExists)
            {
                ViewBag.Error = "Email này đã được đăng ký trên hệ thống!";
                return View();
            }

            // Tạo username từ email
            var username = email.Split('@')[0];
            var usernameExists = await _context.Users.AnyAsync(u => u.Username == username);
            if (usernameExists)
            {
                username += new Random().Next(100, 999).ToString();
            }

            var passwordHash = HashPassword(password);

            var newAdmin = new User
            {
                Id = Guid.NewGuid().ToString(),
                Username = username,
                Email = email,
                FullName = fullName,
                PasswordHash = passwordHash,
                RoleId = 0, // Admin role
                IsApproved = false, // Luôn luôn chờ phê duyệt từ Admin tổng
                CanManageOrders = false,
                CanManageFinance = false,
                CanManageShops = false
            };

            // Tạo ví cho Admin mới
            var wallet = new Wallet
            {
                UserId = newAdmin.Id,
                Balance = 0,
                UpdatedAt = DateTime.Now
            };

            _context.Users.Add(newAdmin);
            _context.Wallets.Add(wallet);

            // Ghi nhận nhật ký hệ thống
            var log = new SystemLog
            {
                Content = $"Tài khoản Admin con {fullName} ({email}) đã tự đăng ký qua trang chủ. Đang chờ phê duyệt.",
                LogType = LogType.System,
                CreatedAt = DateTime.Now
            };
            _context.SystemLogs.Add(log);

            await _context.SaveChangesAsync();

            TempData["SuccessMessage"] = "Đăng ký tài khoản thành công! Vui lòng chờ Admin tổng phê duyệt hoạt động.";
            return RedirectToAction("Login");
        }

        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return RedirectToAction("Login");
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
