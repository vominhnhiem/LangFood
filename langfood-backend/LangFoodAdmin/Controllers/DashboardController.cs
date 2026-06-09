using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFoodAdmin.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using Microsoft.AspNetCore.Authorization;

namespace LangFoodAdmin.Controllers
{
    [Authorize(Roles = "Admin")]
    public class DashboardController : Controller
    {
        private readonly LangFoodDbContext _context;

        public DashboardController(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            var model = await CalculateRevenue();
            return View(model);
        }

        private async Task<DashboardViewModel> CalculateRevenue()
        {
            var now = DateTime.Now;
            var currentYear = now.Year;
            var currentMonth = now.Month;

            // Xác định năm và tháng của tháng trước
            int prevYear = currentYear;
            int prevMonth = currentMonth - 1;
            if (prevMonth == 0)
            {
                prevMonth = 12;
                prevYear = currentYear - 1;
            }

            // Tính doanh thu tháng hiện tại: tổng CommissionFee của các đơn hàng Completed
            decimal currentMonthRevenue = await _context.Orders
                .Where(o => o.Status == "Completed" && o.CreatedAt.Month == currentMonth && o.CreatedAt.Year == currentYear)
                .SumAsync(o => o.CommissionFee);

            // Tính doanh thu tháng trước
            decimal prevMonthRevenue = await _context.Orders
                .Where(o => o.Status == "Completed" && o.CreatedAt.Month == prevMonth && o.CreatedAt.Year == prevYear)
                .SumAsync(o => o.CommissionFee);

            // Tính tỉ lệ tăng trưởng (%)
            decimal growthPercentage = 0;
            if (prevMonthRevenue > 0)
            {
                growthPercentage = ((currentMonthRevenue - prevMonthRevenue) / prevMonthRevenue) * 100;
            }
            else if (currentMonthRevenue > 0)
            {
                growthPercentage = 100;
            }

            return new DashboardViewModel
            {
                CurrentMonthRevenue = currentMonthRevenue,
                GrowthPercentage = Math.Round(growthPercentage, 1)
            };
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
