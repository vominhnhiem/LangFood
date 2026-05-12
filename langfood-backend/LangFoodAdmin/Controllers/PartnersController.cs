using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.Models;
using LangFood.Shared.ViewModels;
using Microsoft.EntityFrameworkCore;
using System.IO;

namespace LangFoodAdmin.Controllers
{
    public class PartnersController : Controller
    {
        private readonly LangFoodDbContext _context;
        private readonly IWebHostEnvironment _hostEnvironment;

        public PartnersController(LangFoodDbContext context, IWebHostEnvironment hostEnvironment)
        {
            _context = context;
            _hostEnvironment = hostEnvironment;
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(CreatePartnerViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return Json(new { success = false, message = "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại!" });
            }

            // Kiểm tra số điện thoại đã tồn tại chưa
            if (await _context.Users.AnyAsync(u => u.PhoneNumber == model.PhoneNumber))
            {
                return Json(new { success = false, message = "Số điện thoại này đã được đăng ký tài khoản!" });
            }

            // Bắt đầu Transaction để đảm bảo an toàn dữ liệu
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // 1. Tạo User (Vai trò Seller)
                    var user = new User
                    {
                        Id = Guid.NewGuid().ToString(),
                        Username = model.PhoneNumber, // Dùng SĐT làm tên đăng nhập luôn
                        PhoneNumber = model.PhoneNumber,
                        FullName = model.FullName,
                        PasswordHash = model.Password, // Lưu ý: Trong thực tế nên Hash Password ở đây
                        RoleId = 2, // 2: Seller
                        IsApproved = true
                    };

                    _context.Users.Add(user);
                    await _context.SaveChangesAsync();

                    // 2. Xử lý lưu ảnh Shop
                    string imageUrl = "/images/shops/default-shop.png"; // Ảnh mặc định
                    if (model.ShopImage != null)
                    {
                        string uploadsFolder = Path.Combine(_hostEnvironment.WebRootPath, "uploads", "shops");
                        if (!Directory.Exists(uploadsFolder))
                        {
                            Directory.CreateDirectory(uploadsFolder);
                        }

                        string uniqueFileName = Guid.NewGuid().ToString() + "_" + model.ShopImage.FileName;
                        string filePath = Path.Combine(uploadsFolder, uniqueFileName);
                        
                        using (var fileStream = new FileStream(filePath, FileMode.Create))
                        {
                            await model.ShopImage.CopyToAsync(fileStream);
                        }
                        imageUrl = "/uploads/shops/" + uniqueFileName;
                    }

                    // 3. Tạo Shop liên kết với User vừa tạo
                    var shop = new Shop
                    {
                        UserId = user.Id,
                        Name = model.ShopName,
                        Address = model.Address,
                        Description = model.Description,
                        ImageUrl = imageUrl,
                        IsActive = true,
                        IsOpen = false // Mặc định tạo xong chưa mở cửa ngay
                    };

                    _context.Shops.Add(shop);
                    await _context.SaveChangesAsync();

                    // Nếu mọi thứ OK thì Commit
                    await transaction.CommitAsync();

                    return Json(new { success = true, message = "Đã tạo tài khoản đối tác và gian hàng thành công!" });
                }
                catch (Exception ex)
                {
                    // Có lỗi thì Rollback toàn bộ
                    await transaction.RollbackAsync();
                    return Json(new { success = false, message = "Lỗi hệ thống: " + ex.Message });
                }
            }
        }
    }
}
