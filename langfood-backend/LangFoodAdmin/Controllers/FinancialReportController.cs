using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFoodAdmin.Models;
using System.Linq;
using System.Threading.Tasks;
using System;
using System.Collections.Generic;

namespace LangFoodAdmin.Controllers
{
    public class FinancialReportController : Controller
    {
        private readonly LangFoodDbContext _context;

        public FinancialReportController(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(string timePeriod = "all")
        {
            ViewBag.CurrentTimePeriod = timePeriod;

            // 1. Tổng doanh thu hệ thống (từ transactions có Type = "FEE" hoặc "ADMIN_FEE" và Status = 1)
            var totalRevenueQuery = _context.Transactions
                .Where(t => (t.Type == "FEE" || t.Type == "ADMIN_FEE") && t.Status == 1);

            // 3. Số đơn hàng hoàn thành (Status = "Delivered")
            var completedOrdersQuery = _context.Orders
                .Where(o => o.Status == "Delivered");

            switch (timePeriod)
            {
                case "today":
                    var today = DateTime.Today;
                    var tomorrow = today.AddDays(1);
                    totalRevenueQuery = totalRevenueQuery.Where(t => t.CreatedAt >= today && t.CreatedAt < tomorrow);
                    completedOrdersQuery = completedOrdersQuery.Where(o => o.CreatedAt >= today && o.CreatedAt < tomorrow);
                    break;
                case "month":
                    var todayMonth = DateTime.Today;
                    var startOfMonth = new DateTime(todayMonth.Year, todayMonth.Month, 1);
                    var startOfNextMonth = startOfMonth.AddMonths(1);
                    totalRevenueQuery = totalRevenueQuery.Where(t => t.CreatedAt >= startOfMonth && t.CreatedAt < startOfNextMonth);
                    completedOrdersQuery = completedOrdersQuery.Where(o => o.CreatedAt >= startOfMonth && o.CreatedAt < startOfNextMonth);
                    break;
                case "year":
                    var todayYear = DateTime.Today;
                    var startOfYear = new DateTime(todayYear.Year, 1, 1);
                    var startOfNextYear = startOfYear.AddYears(1);
                    totalRevenueQuery = totalRevenueQuery.Where(t => t.CreatedAt >= startOfYear && t.CreatedAt < startOfNextYear);
                    completedOrdersQuery = completedOrdersQuery.Where(o => o.CreatedAt >= startOfYear && o.CreatedAt < startOfNextYear);
                    break;
                default:
                    break;
            }

            var totalRevenue = await totalRevenueQuery.SumAsync(t => t.Amount);
            var completedOrdersCount = await completedOrdersQuery.CountAsync();

            // 4. Doanh thu tóm tắt theo từng tháng (Lấy dữ liệu thực tế)
            var completedOrdersList = await completedOrdersQuery
                .Select(o => new { o.CreatedAt })
                .ToListAsync();

            var feeTransactionsList = await totalRevenueQuery
                .Select(t => new { t.CreatedAt, t.Amount })
                .ToListAsync();

            var ordersGrouped = completedOrdersList
                .GroupBy(o => new { o.CreatedAt.Year, o.CreatedAt.Month })
                .ToDictionary(
                    g => $"{g.Key.Month:D2}/{g.Key.Year}",
                    g => g.Count()
                );

            var revenueGrouped = feeTransactionsList
                .GroupBy(t => new { t.CreatedAt.Year, t.CreatedAt.Month })
                .ToDictionary(
                    g => $"{g.Key.Month:D2}/{g.Key.Year}",
                    g => g.Sum(t => t.Amount)
                );

            var allMonths = ordersGrouped.Keys.Union(revenueGrouped.Keys)
                .OrderByDescending(m => {
                    var parts = m.Split('/');
                    if (parts.Length == 2 && int.TryParse(parts[0], out int month) && int.TryParse(parts[1], out int year))
                    {
                        return (year * 100) + month;
                    }
                    return 0;
                })
                .ToList();

            var monthlyData = allMonths.Select(m => new MonthlySummaryViewModel
            {
                MonthYear = m,
                TotalOrders = ordersGrouped.TryGetValue(m, out int orderCount) ? orderCount : 0,
                Revenue = revenueGrouped.TryGetValue(m, out decimal revAmount) ? revAmount : 0m
            }).ToList();

            var viewModel = new FinancialReportViewModel
            {
                TotalRevenue = totalRevenue,
                CompletedOrdersCount = completedOrdersCount,
                MonthlySummaries = monthlyData
            };

            return View(viewModel);
        }
    }
}
