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

        [HttpGet("check-email")]
        public async Task<IActionResult> CheckEmail([FromQuery] string email)
        {
            var exists = await _context.Users.AnyAsync(u => u.Email == email);
            return Ok(new { exists });
        }

        [HttpGet("check-phone")]
        public async Task<IActionResult> CheckPhone([FromQuery] string phone)
        {
            var exists = await _context.Users.AnyAsync(u => u.PhoneNumber == phone);
            return Ok(new { exists });
        }

        [HttpPost("send-otp")]
        public async Task<IActionResult> SendOtp([FromQuery] string email, [FromQuery] string? username)
        {
            if (string.IsNullOrEmpty(email))
                return BadRequest(new { message = "Vui lòng nhập Email." });

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

        // --- CẬP NHẬT: LOGIN BAO GỒM CẢ SHOP VÀ SHIPPER ---
        [HttpPost("login")]
        public async Task<ActionResult<User>> Login([FromBody] User loginRequest)
        {
            var user = await _context.Users
                .Include(u => u.Wallet)
                .Include(u => u.Shop)    // Thêm Shop để lấy ShopId ngay khi login
                .Include(u => u.Shipper) // Thêm Shipper để lấy ShipperId ngay khi login
                .FirstOrDefaultAsync(u => u.Username == loginRequest.Username && u.PasswordHash == loginRequest.PasswordHash);

            if (user == null) return Unauthorized(new { message = "Sai tài khoản hoặc mật khẩu!" });
            return Ok(user);
        }

        [HttpPost("register")]
        public async Task<ActionResult<User>> Register([FromBody] User user)
        {
            if (!_cache.TryGetValue(user.Email + "_verified", out bool isVerified) || !isVerified)
                return BadRequest(new { message = "Email chưa được xác thực OTP!" });

            if (await _context.Users.AnyAsync(u => u.Username == user.Username))
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại!" });

            user.Id = Guid.NewGuid().ToString();
            _cache.Remove(user.Email + "_verified");

            var wallet = new Wallet { UserId = user.Id, Balance = 0, UpdatedAt = DateTime.Now };

            if (!string.IsNullOrEmpty(user.ShopName))
            {
                user.IsApproved = false;
                user.RoleId = 2;
                _context.Users.Add(user);
                _context.Wallets.Add(wallet);
                _context.RoleRequests.Add(new RoleRequest { UserId = user.Id, RequestType = 1, ShopName = user.ShopName, ShopAddress = user.ShopAddress, Status = 0 });
            }
            else
            {
                user.IsApproved = true;
                user.RoleId = 1;
                _context.Users.Add(user);
                _context.Wallets.Add(wallet);
            }

            await _context.SaveChangesAsync();
            return Ok(user);
        }

        // --- FIX: API ĐĂNG KÝ SHIPPER (APPLY SHIPPER) ---
        [HttpPost("apply-shipper")]
        public async Task<IActionResult> ApplyShipper([FromForm] string userId, [FromForm] string? mssv, IFormFile imageProof)
        {
            // Làm sạch userId (xóa dấu ngoặc kép nếu có từ Android gửi qua)
            userId = userId.Replace("\"", "");

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "Người dùng không tồn tại." });

            // Kiểm tra xem đã có hồ sơ đang chờ chưa
            var existingRequest = await _context.RoleRequests
                .FirstOrDefaultAsync(r => r.UserId == userId && r.Status == 0 && r.RequestType == 2);

            if (existingRequest != null)
                return BadRequest(new { message = "Bạn đã có hồ sơ đang chờ duyệt rồi!" });

            // Xử lý lưu ảnh thẻ sinh viên
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

            // Lưu MSSV vào hồ sơ (Lưu vào trường ShopName để Admin thấy)
            var request = new RoleRequest
            {
                UserId = userId,
                RequestType = 2, // 2 là loại Shipper
                ImageProof = imageUrl,
                ShopName = "MSSV: " + mssv,
                Status = 0,
                CreatedAt = DateTime.Now
            };

            _context.RoleRequests.Add(request);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Nộp hồ sơ thành công! Vui lòng chờ Admin duyệt." });
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<User>> GetUserById(string id)
        {
            var user = await _context.Users
                .Include(u => u.Wallet)
                .Include(u => u.Shop)
                .Include(u => u.Shipper)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null) return NotFound();
            return Ok(user);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(string id, [FromBody] User updatedUser)
        {
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
            using (var fileStream = new FileStream(filePath, FileMode.Create)) { await image.CopyToAsync(fileStream); }
            user.AvatarUrl = "/images/avatars/" + uniqueFileName;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Upload thành công", url = user.AvatarUrl });
        }
    }
}