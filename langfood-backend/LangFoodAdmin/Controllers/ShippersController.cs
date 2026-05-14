using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.Models;
using LangFood.Shared.ViewModels;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;
using System;

namespace LangFoodAdmin.Controllers
{
    public class ShippersController : Controller
    {
        private readonly LangFoodDbContext _context;

        public ShippersController(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var viewModel = new ShipperManagementViewModel
            {
                // Lấy yêu cầu nâng cấp Shipper (RequestType = 2) đang chờ (Status = 0)
                PendingShippers = await _context.RoleRequests
                    .Include(r => r.User)
                    .Where(r => r.RequestType == 2 && r.Status == 0)
                    .OrderByDescending(r => r.CreatedAt)
                    .ToListAsync(),

                ActiveShippers = await _context.Shippers
                    .Include(s => s.User)
                    .OrderByDescending(s => s.Id)
                    .ToListAsync()
            };
            return View(viewModel);
        }

        public async Task<IActionResult> Approve(int id)
        {
            var request = await _context.RoleRequests.Include(r => r.User).FirstOrDefaultAsync(r => r.Id == id);
            if (request != null && request.RequestType == 2)
            {
                request.Status = 1; // Duyệt
                var user = request.User;
                if (user != null)
                {
                    user.RoleId = 3;
                    user.IsApproved = true;

                    var existingShipper = await _context.Shippers.FirstOrDefaultAsync(s => s.UserId == user.Id);
                    if (existingShipper == null)
                    {
                        // Lấy MSSV từ ShopName (Android gửi MSSV vào đây)
                        string mssvOnly = request.ShopName?.Replace("MSSV: ", "") ?? "";
                        var shipper = new Shipper
                        {
                            UserId = user.Id,
                            Mssv = mssvOnly,
                            IsApproved = true,
                            IsOnline = false
                        };
                        _context.Shippers.Add(shipper);
                    }
                }
                await _context.SaveChangesAsync();
                TempData["Success"] = "Đã duyệt Shipper thành công!";
            }
            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        public async Task<IActionResult> Reject(int id)
        {
            var request = await _context.RoleRequests.FindAsync(id);
            if (request != null)
            {
                request.Status = 2; // Từ chối
                await _context.SaveChangesAsync();
                TempData["Success"] = "Đã từ chối yêu cầu.";
            }
            return RedirectToAction(nameof(Index));
        }
    }
}