using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFood.Shared.DTOs;

namespace LangFoodBackend.Controller
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

        // ==========================================
        // 1. PHẦN DUYỆT MÓN ĂN (PRODUCTS)
        // ==========================================

        [HttpGet("pending-products")]
        public async Task<IActionResult> GetPendingProducts()
        {
            var products = await _context.Products
                .Include(p => p.Shop)
                    .ThenInclude(s => s.User)
                .Where(p => p.Status == 0)
                .Select(p => new ProductDTO
                {
                    Id = p.Id,
                    Name = p.Name,
                    Price = p.Price,
                    ImageUrl = p.ImageUrl,
                    SellerName = p.Shop != null ? (p.Shop.Name ?? p.Shop.User.FullName) : "Ẩn danh",
                    Status = p.Status
                }).ToListAsync();

            return Ok(products);
        }

        [HttpPost("approve-product/{id}")]
        public async Task<IActionResult> ApproveProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();

            product.Status = 1; // Chuyển trạng thái thành Đã Duyệt
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã duyệt món ăn thành công!" });
        }

        // ==========================================
        // 2. PHẦN DUYỆT QUYỀN (ROLE REQUESTS)
        // ==========================================

        [HttpGet("pending-role-requests")]
        public async Task<IActionResult> GetPendingRequests()
        {
            var requests = await _context.RoleRequests
                .Include(r => r.User)
                .Where(r => r.Status == 0) // Lấy yêu cầu đang chờ
                .Select(r => new RoleRequestDTO
                {
                    Id = r.Id,
                    UserId = r.UserId,
                    FullName = r.User.FullName,
                    RequestType = r.RequestType,
                    ShopName = r.ShopName,
                    ShopAddress = r.ShopAddress,
                    ImageProof = r.ImageProof,
                    Status = r.Status
                })
                .ToListAsync();

            return Ok(requests);
        }

        [HttpPost("approve-role-request/{id}")]
        public async Task<IActionResult> ApproveRequest(int id)
        {
            var request = await _context.RoleRequests.FindAsync(id);
            if (request == null) return NotFound(new { message = "Không tìm thấy yêu cầu." });

            var user = await _context.Users.FindAsync(request.UserId);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng." });

            request.Status = 1; // Đã duyệt yêu cầu
            user.IsApproved = true;

            if (request.RequestType == 1) // Seller
            {
                user.RoleId = 2;
                // Tạo Shop mới cho người bán
                if (user.Shop == null)
                {
                    var newShop = new Shop
                    {
                        UserId = user.Id,
                        Name = request.ShopName ?? (user.FullName + "'s Shop"),
                        Address = request.ShopAddress ?? user.KtxBuilding ?? "KTX Khu B",
                        IsActive = true,
                        IsOpen = true
                    };
                    _context.Shops.Add(newShop);
                }
            }
            else if (request.RequestType == 2) // Shipper
            {
                user.RoleId = 3;
                // Tạo hồ sơ Shipper mới
                if (user.Shipper == null)
                {
                    var newShipper = new Shipper
                    {
                        UserId = user.Id,
                        IsApproved = true,
                        IsOnline = false,
                        WalletBalance = 0
                    };
                    _context.Shippers.Add(newShipper);
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã duyệt nâng cấp quyền thành công!" });
        }
    }
}
