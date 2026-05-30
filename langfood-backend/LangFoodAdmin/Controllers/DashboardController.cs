using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFoodAdmin.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodAdmin.Controllers
{
    public class DashboardController : Controller
    {
        private readonly LangFoodDbContext _context;

        public DashboardController(LangFoodDbContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> GetRecentActivities()
        {
            try
            {
                // 1. Lấy 5 Đơn hàng mới nhất
                var orders = await _context.Orders
                    .OrderByDescending(o => o.Id)
                    .Take(5)
                    .Select(o => new SystemActivityVM
                    {
                        Message = $"Đơn hàng #{o.Id} trị giá {o.TotalAmount:N0}₫ vừa được tạo.",
                        CreatedAt = o.CreatedAt,
                        Type = "Success"
                    })
                    .ToListAsync();

                // 2. Lấy 3 Cửa hàng mới nhất
                var shopsDb = await _context.Shops
                    .OrderByDescending(s => s.Id)
                    .Take(3)
                    .ToListAsync();

                var shops = new List<SystemActivityVM>();
                foreach (var s in shopsDb)
                {
                    var reqTime = await _context.RoleRequests
                        .Where(r => r.UserId == s.UserId && r.RequestType == 1)
                        .Select(r => r.CreatedAt)
                        .FirstOrDefaultAsync();

                    shops.Add(new SystemActivityVM
                    {
                        Message = $"Đối tác '{s.Name}' đã kích hoạt gian hàng thành công.",
                        CreatedAt = reqTime == default ? DateTime.Now : reqTime,
                        Type = "Warning"
                    });
                }

                // 3. Lấy 2 Khiếu nại mới nhất
                var complaints = await _context.Complaints
                    .OrderByDescending(c => c.Id)
                    .Take(2)
                    .Select(c => new SystemActivityVM
                    {
                        Message = $"Đơn hàng #{c.OrderId} bị khiếu nại với lý do: '{c.Reason}'.",
                        CreatedAt = c.CreatedAt,
                        Type = "Danger"
                    })
                    .ToListAsync();

                // Gom lại và sắp xếp giảm dần theo CreatedAt, lấy tối đa 10 dòng
                var allActivities = orders
                    .Concat(shops)
                    .Concat(complaints)
                    .OrderByDescending(a => a.CreatedAt)
                    .Take(10)
                    .ToList();

                return Json(allActivities);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
