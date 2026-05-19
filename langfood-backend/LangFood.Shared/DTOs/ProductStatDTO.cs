using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LangFood.Shared.DTOs
{

    namespace LangFood.Shared.DTOs
    {
        public class ProductStatDTO
        {
            public string ProductName { get; set; } = string.Empty;
            public int TotalQuantity { get; set; } // Số lượng đã bán
            public decimal TotalRevenue { get; set; } // Tổng tiền thu được từ món này
        }
    }
}