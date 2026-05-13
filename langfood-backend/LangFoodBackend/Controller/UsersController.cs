using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using Microsoft.Extensions.Caching.Memory;
using LangFoodBackend.Services;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodBackend.Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly LangFoodDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly EmailService _emailService;

        public UsersController(LangFoodDbContext context, IMemoryCache cache, EmailService emailService)
        {
            _context = context;
            _cache = cache;
            _emailService = emailService;
        }

        // 1. Check trùng Email
        [HttpGet("check-email")]
        public async Task<IActionResult> CheckEmail([FromQuery] string email)
        {
            var exists = await _context.Users.AnyAsync(u => u.Email == email);
            return Ok(new { exists });
        }

        // 2. Check trùng Số điện thoại
        [HttpGet("check-phone")]
        public async Task<IActionResult> CheckPhone([FromQuery] string phone)
        {
            var exists = await _context.Users.AnyAsync(u => u.PhoneNumber == phone);
            return Ok(new { exists });
        }

        // --- 1. API GỬI MÃ OTP ---
        [HttpPost("send-otp")]
        public async Task<IActionResult> SendOtp([FromQuery] string email, [FromQuery] string? username)
        {
            if (string.IsNullOrEmpty(email))
                return BadRequest(new { message = "Vui lòng nhập Email." });

            if (!string.IsNullOrEmpty(username))
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username && u.Email == email);
                if (user == null)
                {
                    return BadRequest(new { message = "Tên đăng nhập hoặc Email không chính xác!" });
                }
            }

            string otp = new Random().Next(100000, 999999).ToString();
            _cache.Set(email, otp, TimeSpan.FromMinutes(5));

            try
            {
                await _emailService.SendOtpAsync(email, otp);
                return Ok(new { message = "Đã gửi mã OTP thành công!" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi gửi mail: " + ex.Message });
            }
        }

        // --- 2. API XÁC THỰC MÃ OTP ---
        [HttpPost("verify-otp")]
        public IActionResult VerifyOtp([FromQuery] string email, [FromQuery] string otp)
        {
            if (_cache.TryGetValue(email, out string sendedOtp))
            {
                if (sendedOtp == otp)
                {
                    _cache.Set(email + "_verified", true, TimeSpan.FromMinutes(10));
                    _cache.Remove(email);
                    return Ok(new { success = true, message = "Xác thực thành công!" });
                }
            }
            return BadRequest(new { success = false, message = "Mã OTP không đúng hoặc đã hết hạn." });
        }

        // POST: api/Users/login
        [HttpPost("login")]
        public async Task<ActionResult<User>> Login([FromBody] User loginRequest)
        {
            var user = await _context.Users
                .Include(u => u.Wallet) // THÊM: Lấy luôn thông tin ví khi đăng nhập
                .FirstOrDefaultAsync(u => u.Username == loginRequest.Username && u.PasswordHash == loginRequest.PasswordHash);

            if (user == null)
            {
                return Unauthorized(new { message = "Sai tài khoản hoặc mật khẩu rồi mày ơi!" });
            }

            return Ok(user);
        }

        // POST: api/Users/register
        [HttpPost("register")]
        public async Task<ActionResult<User>> Register([FromBody] User user)
        {
            if (!_cache.TryGetValue(user.Email + "_verified", out bool isVerified) || !isVerified)
            {
                return BadRequest(new { message = "Email chưa được xác thực OTP!" });
            }

            if (await _context.Users.AnyAsync(u => u.Username == user.Username))
            {
                return BadRequest(new { message = "Tên đăng nhập này có người hớt rồi!" });
            }

            user.Id = Guid.NewGuid().ToString();
            _cache.Remove(user.Email + "_verified");

            // --- TỰ ĐỘNG TẠO VÍ CHO USER MỚI ---
            var wallet = new Wallet
            {
                UserId = user.Id,
                Balance = 0,
                UpdatedAt = DateTime.Now
            };

            // --- PHÂN LOẠI ĐĂNG KÝ VÀ PHÂN QUYỀN (BẢO MẬT) ---
            // Nếu có ShopName -> Đăng ký làm chủ quán (Merchant/Seller)
            if (!string.IsNullOrEmpty(user.ShopName)) 
            {
                user.IsApproved = false;
                user.RoleId = 2; // Gán RoleId = 2 cho Chủ quán (Merchant)
                
                _context.Users.Add(user);
                _context.Wallets.Add(wallet); // Lưu ví

                var roleRequest = new RoleRequest
                {
                    UserId = user.Id,
                    RequestType = 1,
                    ShopName = user.ShopName,
                    ShopAddress = user.ShopAddress,
                    Status = 0
                };
                _context.RoleRequests.Add(roleRequest);
                await _context.SaveChangesAsync();
                return Ok(user);
            }
            else // Sinh viên (Student)
            {
                user.IsApproved = true;
                user.RoleId = 1; // BẮT BUỘC gán RoleId = 1 cho Sinh viên, tránh mặc định là 0 (Admin)
                
                _context.Users.Add(user);
                _context.Wallets.Add(wallet); // Lưu ví
                await _context.SaveChangesAsync();
                return Ok(user);
            }
        }

        [HttpGet("check-username")]
        public async Task<IActionResult> CheckUsername([FromQuery] string username)
        {
            var exists = await _context.Users.AnyAsync(u => u.Username == username);
            return Ok(new { exists });
        }

        [HttpPost("apply-shipper")]
        public async Task<IActionResult> ApplyShipper([FromForm] string userId, IFormFile imageProof)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("User không tồn tại.");

            var existingRequest = await _context.RoleRequests
                .FirstOrDefaultAsync(r => r.UserId == userId && r.Status == 0);

            if (existingRequest != null)
                return BadRequest("Bạn đã có hồ sơ đang chờ duyệt.");

            string imageUrl = null;
            if (imageProof != null && imageProof.Length > 0)
            {
                var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "proofs");
                if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

                var uniqueFileName = Guid.NewGuid().ToString() + "_" + imageProof.FileName;
                var filePath = Path.Combine(uploadsFolder, uniqueFileName);

                using (var fileStream = new FileStream(filePath, FileMode.Create))
                {
                    await imageProof.CopyToAsync(fileStream);
                }
                imageUrl = "/images/proofs/" + uniqueFileName;
            }

            var request = new RoleRequest
            {
                UserId = userId,
                RequestType = 2,
                ImageProof = imageUrl,
                Status = 0
            };

            _context.RoleRequests.Add(request);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Nộp hồ sơ thành công!" });
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<User>> GetUserById(string id)
        {
            var user = await _context.Users
                .Include(u => u.Wallet) // Lấy kèm ví
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null) return NotFound();
            return Ok(user);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(string id, [FromBody] User updatedUser)
        {
            if (id != updatedUser.Id) return BadRequest("ID không khớp.");
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound();

            user.FullName = updatedUser.FullName;
            user.PhoneNumber = updatedUser.PhoneNumber;

            user.BuildingId = updatedUser.BuildingId;
            user.KtxRoom = updatedUser.KtxRoom;

            await _context.SaveChangesAsync();
            return Ok(user);
        }

        [HttpPost("upload-avatar/{userId}")]
        public async Task<IActionResult> UploadAvatar(string userId, IFormFile image)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound();

            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "images", "avatars");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

            var uniqueFileName = Guid.NewGuid().ToString() + "_" + image.FileName;
            var filePath = Path.Combine(uploadsFolder, uniqueFileName);

            using (var fileStream = new FileStream(filePath, FileMode.Create))
            {
                await image.CopyToAsync(fileStream);
            }

            user.AvatarUrl = "/images/avatars/" + uniqueFileName;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Upload thành công", url = user.AvatarUrl });
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromQuery] string id, [FromQuery] string oldPassword, [FromQuery] string newPassword)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng!" });

            if (user.PasswordHash != oldPassword)
            {
                return BadRequest(new { message = "Mật khẩu cũ không chính xác!" });
            }

            user.PasswordHash = newPassword;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đổi mật khẩu thành công rồi đó mày!" });
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromQuery] string email, [FromQuery] string newPassword)
        {
            if (!_cache.TryGetValue(email + "_verified", out bool isVerified) || !isVerified)
            {
                return BadRequest(new { message = "Mày chưa xác thực OTP mà đòi đổi mật khẩu à?" });
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user == null) return NotFound(new { message = "Email này không tồn tại trên hệ thống!" });

            user.PasswordHash = newPassword;

            _cache.Remove(email + "_verified");
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đổi mật khẩu thành công rồi đó mày!" });
        }

        private bool UserExists(string id)
        {
            return _context.Users.Any(e => e.Id == id);
        }
    }
}