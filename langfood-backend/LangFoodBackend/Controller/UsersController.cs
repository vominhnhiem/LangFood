using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFoodBackend.Models; // Thay bằng namespace đúng của mày

namespace LangFoodBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public UsersController(LangFoodDbContext context)
        {
            _context = context;
        }

        // POST: api/Users/login
        [HttpPost("login")]
        public async Task<ActionResult<User>> Login([FromBody] User loginRequest)
        {
            // Tìm user dựa trên username và password (đang làm đơn giản, sau này nên dùng Bcrypt)
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == loginRequest.Username && u.PasswordHash == loginRequest.PasswordHash);

            if (user == null)
            {
                return Unauthorized("Sai tài khoản hoặc mật khẩu rồi mày ơi!");
            }

            return Ok(user); // Trả về nguyên object User cho Android hứng
        }

        // POST: api/Users/register
        [HttpPost("register")]
        public async Task<ActionResult<User>> Register([FromBody] User user)
        {
            // Kiểm tra xem username đã tồn tại chưa
            if (await _context.Users.AnyAsync(u => u.Username == user.Username))
            {
                return BadRequest("Tên đăng nhập này có người hớt rồi!");
            }

            user.Id = Guid.NewGuid().ToString(); // Tạo ID duy nhất (nvarchar 450)
            
            if (user.AccountType == 1) // Ngoại khu
            {
                user.IsApproved = false;
                user.RoleId = 1; // Tạm thời là Buyer
                _context.Users.Add(user);

                var roleRequest = new RoleRequest
                {
                    UserId = user.Id,
                    RequestType = 1, // Seller
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
                user.IsApproved = true; // Sinh viên nội khu có thể dùng app ngay
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
                return Ok(user);
            }
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
                RequestType = 2, // Shipper
                ImageProof = imageUrl,
                Status = 0
            };

            _context.RoleRequests.Add(request);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Nộp hồ sơ thành công, vui lòng chờ duyệt!" });
        }
        // GET: api/Users/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<User>> GetUserById(string id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound();
            }
            return Ok(user);
        }

        // PUT: api/Users/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(string id, [FromBody] User updatedUser)
        {
            if (id != updatedUser.Id)
            {
                return BadRequest("ID không khớp.");
            }

            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound();
            }

            user.FullName = updatedUser.FullName;
            user.PhoneNumber = updatedUser.PhoneNumber;
            user.KtxBuilding = updatedUser.KtxBuilding;
            user.KtxRoom = updatedUser.KtxRoom;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UserExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return Ok(user);
        }

        // POST: api/Users/upload-avatar/{userId}
        [HttpPost("upload-avatar/{userId}")]
        public async Task<IActionResult> UploadAvatar(string userId, IFormFile image)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("Không tìm thấy user.");

            if (image == null || image.Length == 0)
                return BadRequest("File ảnh không hợp lệ.");

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

        private bool UserExists(string id)
        {
            return _context.Users.Any(e => e.Id == id);
        }
    }
}