using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using Microsoft.Extensions.Caching.Memory;
using LangFoodBackend.Services; // Đảm bảo bạn đã tạo thư mục Services và file EmailService.cs
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
        // Cập nhật lại hàm SendOtp trong UsersController.cs
        [HttpPost("send-otp")]
        public async Task<IActionResult> SendOtp([FromQuery] string email, [FromQuery] string? username)
        {
            if (string.IsNullOrEmpty(email))
                return BadRequest(new { message = "Vui lòng nhập Email." });

            // TRƯỜNG HỢP 1: Nếu có truyền username -> Dùng cho Quên mật khẩu (Cần check tồn tại)
            if (!string.IsNullOrEmpty(username))
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Username == username && u.Email == email);
                if (user == null)
                {
                    return BadRequest(new { message = "Tên đăng nhập hoặc Email không chính xác!" });
                }
            }
            // TRƯỜNG HỢP 2: Nếu username null -> Dùng cho Đăng ký mới (Không cần check user)
            // (Lưu ý: RegisterActivity đã check trùng email trước khi gọi hàm này rồi nên cứ thế gửi thôi)

            // Tạo mã OTP
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
                    // Lưu trạng thái đã xác thực vào cache trong 10 phút để bước Register kiểm tra
                    _cache.Set(email + "_verified", true, TimeSpan.FromMinutes(10));
                    _cache.Remove(email); // Xóa mã OTP sau khi dùng xong
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
            // KIỂM TRA: Chỉ cho đăng ký nếu email đã qua bước verify-otp
            if (!_cache.TryGetValue(user.Email + "_verified", out bool isVerified) || !isVerified)
            {
                return BadRequest(new { message = "Email chưa được xác thực OTP!" });
            }

            if (await _context.Users.AnyAsync(u => u.Username == user.Username))
            {
                return BadRequest(new { message = "Tên đăng nhập này có người hớt rồi!" });
            }

            user.Id = Guid.NewGuid().ToString();
            _cache.Remove(user.Email + "_verified"); // Xóa trạng thái xác thực sau khi tạo xong tài khoản

            if (user.AccountType == 1) // Ngoại khu
            {
                user.IsApproved = false;
                user.RoleId = 1;
                _context.Users.Add(user);

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
            else // Sinh viên
            {
                user.IsApproved = true;
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
                return Ok(user);
            }
        }

        // Thêm vào file UsersController.cs
        [HttpGet("check-username")]
        public async Task<IActionResult> CheckUsername([FromQuery] string username)
        {
            var exists = await _context.Users.AnyAsync(u => u.Username == username);
            return Ok(new { exists });
        }
        // POST: api/Users/apply-shipper
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
            var user = await _context.Users.FindAsync(id);
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
            user.KtxBuilding = updatedUser.KtxBuilding;
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
        // Thêm vào trong file UsersController.cs (Dự án Backend)
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromQuery] string id, [FromQuery] string oldPassword, [FromQuery] string newPassword)
        {
            // 1. Tìm user theo Id
            var user = await _context.Users.FindAsync(id);
            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng!" });

            // 2. Kiểm tra mật khẩu cũ (So khớp trực tiếp vì database của bạn đang lưu text thuần)
            if (user.PasswordHash != oldPassword)
            {
                return BadRequest(new { message = "Mật khẩu cũ không chính xác!" });
            }

            // 3. Cập nhật mật khẩu mới
            user.PasswordHash = newPassword;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đổi mật khẩu thành công rồi đó mày!" });
        }
        // --- 3. API ĐẶT LẠI MẬT KHẨU (Dùng sau khi VerifyOtp thành công) ---
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromQuery] string email, [FromQuery] string newPassword)
        {
            // Kiểm tra xem email này đã qua bước xác thực OTP chưa (tận dụng lại cache verified của mày)
            if (!_cache.TryGetValue(email + "_verified", out bool isVerified) || !isVerified)
            {
                return BadRequest(new { message = "Mày chưa xác thực OTP mà đòi đổi mật khẩu à?" });
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
            if (user == null) return NotFound(new { message = "Email này không tồn tại trên hệ thống!" });

            // Cập nhật mật khẩu mới (nhớ hash mật khẩu nếu mày có dùng mã hóa nhé)
            user.PasswordHash = newPassword;

            _cache.Remove(email + "_verified"); // Đổi xong thì xóa cache xác thực đi
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đổi mật khẩu thành công rồi đó mày!" });
        }
        private bool UserExists(string id)
        {
            return _context.Users.Any(e => e.Id == id);
        }
    }
}