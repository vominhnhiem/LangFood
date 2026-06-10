using System;
using System.Collections.Generic;
using LangFood.Shared.Models;

namespace LangFoodAdmin.Models
{
    public class DashboardViewModel
    {
        public int PendingWithdrawalCount { get; set; }
        public int PendingShipperCount { get; set; }
        public int PendingShopCount { get; set; }
        public int PendingAdminCount { get; set; }
        public List<SystemLog> LatestLogs { get; set; } = new();

        // New properties for dynamic database stats
        public int TotalOrdersThisMonth { get; set; }
        public int TotalUsers { get; set; }
        public List<Order> LatestOrders { get; set; } = new();
    }
}
