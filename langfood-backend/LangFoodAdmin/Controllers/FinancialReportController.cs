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

        public async Task<IActionResult> Index()
        {
            // 1. Tổng doanh thu hệ thống (từ transactions có Type = "FEE" hoặc "ADMIN_FEE" và Status = 1)
            var totalRevenue = await _context.Transactions
                .Where(t => (t.Type == "FEE" || t.Type == "ADMIN_FEE") && t.Status == 1)
                .SumAsync(t => t.Amount);

            // 3. Số đơn hàng hoàn thành (Status = "Delivered")
            var completedOrdersCount = await _context.Orders
                .CountAsync(o => o.Status == "Delivered");

            // 4. Doanh thu tóm tắt theo từng tháng (Lấy dữ liệu thực tế)
            var completedOrdersList = await _context.Orders
                .Where(o => o.Status == "Delivered")
                .Select(o => new { o.CreatedAt })
                .ToListAsync();

            var feeTransactionsList = await _context.Transactions
                .Where(t => (t.Type == "FEE" || t.Type == "ADMIN_FEE") && t.Status == 1)
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
