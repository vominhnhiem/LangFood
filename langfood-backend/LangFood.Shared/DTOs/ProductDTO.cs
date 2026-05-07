using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LangFood.Shared.DTOs
{
    public class ProductDTO
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }
        public string? SellerName { get; set; } // Để Admin biết món này của ai
        public string? CategoryName { get; set; }
        public int Status { get; set; } // 0: Pending, 1: Approved, 2: Rejected
    }
}