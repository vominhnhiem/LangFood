using System;
using System.Collections.Generic;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using LangFood.Shared.DTOs.LangFood.Shared.DTOs;

namespace LangFood.Shared.DTOs
{
    public class DetailedShopStatsDto
    {
        // Thống kê nhanh hôm nay
        public int TodayOrderCount { get; set; }
        public decimal TodayRevenue { get; set; }

        // Thống kê tháng hiện tại
        public decimal MonthRevenue { get; set; }

        // Thống kê chi tiết theo bộ lọc thời gian (Start Date -> End Date)
        public int TotalOrders { get; set; }
        public decimal TotalRevenue { get; set; }
        public int SuccessOrders { get; set; }
        public int FailedOrders { get; set; }

        // Đánh giá (nếu vẫn muốn giữ logic này ở backend)
        public double AverageRating { get; set; }

        // Danh sách Top món ăn bán chạy (Dữ liệu cho biểu đồ cột)
        public List<ProductStatDTO> ProductStats { get; set; } = new List<ProductStatDTO>();
    }
}
