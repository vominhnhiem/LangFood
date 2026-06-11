using System.Collections.Generic;

namespace LangFoodAdmin.Models
{
    public class FinancialReportViewModel
    {
        public decimal TotalRevenue { get; set; } = 145000000; // 145,000,000đ
        public int CompletedOrdersCount { get; set; } = 1250;

        public List<MonthlySummaryViewModel> MonthlySummaries { get; set; } = new();
    }

    public class MonthlySummaryViewModel
    {
        public string MonthYear { get; set; } = string.Empty; // "05/2026"
        public int TotalOrders { get; set; }
        public decimal Revenue { get; set; }
    }
}
