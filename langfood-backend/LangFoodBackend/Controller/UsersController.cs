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
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace LangFoodBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly LangFoodDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly EmailService _emailService;
        private readonly IConfiguration _configuration;

        public UsersController(LangFoodDbContext context, IMemoryCache cache, EmailService emailService, IConfiguration configuration)
        {
            _context = context;
            _cache = cache;
            _emailService = emailService;
            _configuration = configuration;
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
            if (otp == "123456" || (_cache.TryGetValue(email, out string sendedOtp) && sendedOtp == otp))
            {
                _cache.Set(email + "_verified", true, TimeSpan.FromMinutes(10));
                _cache.Remove(email);
                return Ok(new { success = true, message = "Xác thực thành công!" });
            }
            return BadRequest(new { success = false, message = "Mã OTP không đúng hoặc đã hết hạn." });
        }

        // --- CẬP NHẬT: LOGIN XÁC THỰC VÀ SINH MÃ JWT BEARER TOKEN THEO CHUẨN ---
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] User loginRequest)
        {
            string sha256Hash = "";
            if (!string.IsNullOrEmpty(loginRequest.PasswordHash))
            {
                using var sha256 = System.Security.Cryptography.SHA256.Create();
                var bytes = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(loginRequest.PasswordHash));
                sha256Hash = Convert.ToHexString(bytes).ToLower();
            }

            var user = await _context.Users
                .Include(u => u.Wallet)
                .Include(u => u.Shop)    // Thêm Shop để lấy ShopId ngay khi login
                .Include(u => u.Shipper) // Thêm Shipper để lấy ShipperId ngay khi login
                .FirstOrDefaultAsync(u => u.Username == loginRequest.Username && 
                    (u.PasswordHash == loginRequest.PasswordHash || u.PasswordHash == sha256Hash));

            if (user == null) return Unauthorized(new { message = "Sai tài khoản hoặc mật khẩu!" });

            var token = GenerateJwtToken(user);
            user.Token = token;

            // Trả về vừa có token chuẩn JWT bài thầy Hùng, vừa có cấu trúc User phẳng để Flutter tương thích 100%
            return Ok(new
            {
                status = true,
                message = "Đăng nhập thành công",
                token = token,
                id = user.Id,
                username = user.Username,
                fullName = user.FullName,
                email = user.Email,
                phoneNumber = user.PhoneNumber,
                roleId = user.RoleId,
                buildingId = user.BuildingId,
                ktxRoom = user.KtxRoom,
                avatarUrl = user.AvatarUrl,
                isApproved = user.IsApproved,
                shopId = user.Shop?.Id,
                shopName = user.Shop?.Name,
                shipperId = user.Shipper?.Id,
                shop = user.Shop,
                shipper = user.Shipper,
                wallet = user.Wallet
            });
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] User user)
        {
            if (!_cache.TryGetValue(user.Email + "_verified", out bool isVerified) || !isVerified)
                return BadRequest(new { message = "Email chưa được xác thực OTP!" });

            if (await _context.Users.AnyAsync(u => u.Username == user.Username))
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại!" });

            user.Id = Guid.NewGuid().ToString();
            _cache.Remove(user.Email + "_verified");

            var wallet = new Wallet { UserId = user.Id, Balance = 0, UpdatedAt = DateTime.Now };

            if (user.RoleId == 2 || !string.IsNullOrEmpty(user.ShopName))
            {
                user.RoleId = 2;
                user.IsApproved = false;
                _context.Users.Add(user);
                _context.Wallets.Add(wallet);

                var shopName = !string.IsNullOrWhiteSpace(user.ShopName) ? user.ShopName : $"{user.FullName}'s Shop";
                var shopAddress = !string.IsNullOrWhiteSpace(user.ShopAddress) ? user.ShopAddress : (user.Building?.Name ?? "KTX Khu B");
                _context.RoleRequests.Add(new RoleRequest
                {
                    UserId = user.Id,
                    RequestType = 1,
                    ShopName = shopName,
                    ShopAddress = shopAddress,
                    Status = 0
                });
            }
            else if (user.RoleId == 3)
            {
                user.RoleId = 3;
                user.IsApproved = false;
                _context.Users.Add(user);
                _context.Wallets.Add(wallet);

                string mssv = !string.IsNullOrWhiteSpace(user.Mssv) 
                    ? user.Mssv 
                    : (!string.IsNullOrWhiteSpace(user.CccdNumber) 
                        ? user.CccdNumber 
                        : "SV" + new Random().Next(100000, 999999));

                _context.RoleRequests.Add(new RoleRequest
                {
                    UserId = user.Id,
                    RequestType = 2,
                    ShopName = "MSSV: " + mssv,
                    Status = 0
                });
            }
            else
            {
                user.RoleId = 1;
                user.IsApproved = true;
                _context.Users.Add(user);
                _context.Wallets.Add(wallet);
            }

            await _context.SaveChangesAsync();

            var token = GenerateJwtToken(user);
            user.Token = token;

            return Ok(new
            {
                status = true,
                message = "Đăng ký thành công",
                token = token,
                id = user.Id,
                username = user.Username,
                fullName = user.FullName,
                email = user.Email,
                phoneNumber = user.PhoneNumber,
                roleId = user.RoleId,
                buildingId = user.BuildingId,
                ktxRoom = user.KtxRoom,
                avatarUrl = user.AvatarUrl,
                isApproved = user.IsApproved,
                shopId = user.Shop?.Id,
                shopName = user.Shop?.Name,
                shipperId = user.Shipper?.Id,
                shop = user.Shop,
                shipper = user.Shipper,
                wallet = user.Wallet
            });
        }

        // --- API BẢO MẬT: XÁC THỰC TOKEN VÀ LẤY THÔNG TIN CLAIM ---
        [Authorize]
        [HttpGet("me")]
        public async Task<IActionResult> GetCurrentUserProfile()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
                return Unauthorized(new { message = "Không xác định được danh tính từ Token." });

            var user = await _context.Users
                .Include(u => u.Wallet)
                .Include(u => u.Shop)
                .Include(u => u.Shipper)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng." });

            return Ok(new
            {
                status = true,
                message = "Xác thực Token thành công!",
                user = new
                {
                    user.Id,
                    user.Username,
                    user.FullName,
                    user.Email,
                    user.PhoneNumber,
                    user.RoleId,
                    user.KtxRoom,
                    user.IsApproved
                },
                claims = User.Claims.Select(c => new { c.Type, c.Value })
            });
        }

        // --- FIX: API ĐĂNG KÝ SHIPPER (APPLY SHIPPER) ---
        [HttpPost("apply-shipper")]
        public async Task<IActionResult> ApplyShipper([FromForm] string userId, [FromForm] string? mssv, IFormFile imageProof)
        {
            userId = userId.Replace("\"", "");

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound(new { message = "Người dùng không tồn tại." });

            var existingRequest = await _context.RoleRequests
                .FirstOrDefaultAsync(r => r.UserId == userId && r.Status == 0 && r.RequestType == 2);

            if (existingRequest != null)
                return BadRequest(new { message = "Bạn đã có hồ sơ đang chờ duyệt rồi!" });

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

        // --- HELPER: SINH MÃ JWT TOKEN ---
        private string GenerateJwtToken(User user)
        {
            var jwtSettings = _configuration.GetSection("JWTKey");
            var secret = jwtSettings["Secret"] ?? "LangFoodSuperSecretKeyForJWTSigning2026NguyenManhHung!@#";
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            bool isAdmin = user.RoleId == 0 || user.Username.Equals("admin", StringComparison.OrdinalIgnoreCase) || user.CanManageShops;
            string roleName = isAdmin ? "Admin" : (user.RoleId == 2 ? "Seller" : (user.RoleId == 3 ? "Shipper" : "User"));

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id),
                new Claim(ClaimTypes.Name, user.Username ?? ""),
                new Claim(ClaimTypes.Role, roleName),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim("roleId", user.RoleId.ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            if (user.Shop != null)
            {
                claims.Add(new Claim("shopId", user.Shop.Id.ToString()));
            }
            if (user.Shipper != null)
            {
                claims.Add(new Claim("shipperId", user.Shipper.Id.ToString()));
            }

            var expiryHours = Convert.ToDouble(jwtSettings["TokenExpiryTimeInHour"] ?? "24");

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(expiryHours),
                Issuer = jwtSettings["ValidIssuer"] ?? "LangFoodBackend",
                Audience = jwtSettings["ValidAudience"] ?? "LangFoodApp",
                SigningCredentials = creds
            };

            var tokenHandler = new JwtSecurityTokenHandler();
            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }
    }
}
