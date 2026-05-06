using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFoodBackend.Models;

namespace LangFoodBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminApiController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public AdminApiController(LangFoodDbContext context)
        {
            _context = context;
        }

        // GET: api/adminapi/pending-requests
        [HttpGet("pending-requests")]
        public async Task<IActionResult> GetPendingRequests()
        {
            var requests = await _context.RoleRequests
                .Include(r => r.User)
                .Where(r => r.Status == 0) // 0: Pending
                .Select(r => new
                {
                    r.Id,
                    r.UserId,
                    UserName = r.User.FullName ?? r.User.Username,
                    r.RequestType,
                    RequestTypeName = r.RequestType == 1 ? "Người bán (Seller)" : "Shipper nội khu",
                    r.ImageProof,
                    r.ShopName,
                    r.ShopAddress,
                    r.CreatedAt
                })
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return Ok(requests);
        }

        // PUT: api/adminapi/approve-request/{id}
        [HttpPut("approve-request/{id}")]
        public async Task<IActionResult> ApproveRequest(int id)
        {
            var request = await _context.RoleRequests
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (request == null)
            {
                return NotFound(new { message = "Không tìm thấy yêu cầu này." });
            }

            if (request.Status != 0)
            {
                return BadRequest(new { message = "Yêu cầu này đã được xử lý trước đó." });
            }

            // 1. Cập nhật trạng thái request thành Approved (1)
            request.Status = 1;

            // 2. Nâng cấp quyền User và set IsApproved
            request.User.IsApproved = true;

            if (request.RequestType == 1) // Seller
            {
                request.User.RoleId = 2; // Seller Role
                request.User.ShopName = request.ShopName;
                request.User.ShopAddress = request.ShopAddress;
            }
            else if (request.RequestType == 2) // Shipper
            {
                request.User.RoleId = 3; // Shipper Role
            }

            await _context.SaveChangesAsync();

            return Ok(new { message = "Duyệt yêu cầu thành công!", roleId = request.User.RoleId });
        }

        // PUT: api/adminapi/reject-request/{id}
        [HttpPut("reject-request/{id}")]
        public async Task<IActionResult> RejectRequest(int id)
        {
            var request = await _context.RoleRequests.FindAsync(id);

            if (request == null)
            {
                return NotFound(new { message = "Không tìm thấy yêu cầu này." });
            }

            if (request.Status != 0)
            {
                return BadRequest(new { message = "Yêu cầu này đã được xử lý trước đó." });
            }

            request.Status = 2; // Rejected
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã từ chối yêu cầu." });
        }
    }
}
