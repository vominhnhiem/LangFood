using System;

namespace LangFood.Shared.DTOs
{
    public class ProductDTO
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; } // Thêm mô tả
        public decimal Price { get; set; }
        public string? ImageUrl { get; set; }

        public int ShopId { get; set; } // Thêm Id để dễ xử lý logic
        public string? SellerName { get; set; }

        public int CategoryId { get; set; }
        public string? CategoryName { get; set; }

        public int Status { get; set; } // 0: Pending, 1: Approved, 2: Rejected
        public bool IsAvailable { get; set; } = true; // Trạng thái còn hàng hay hết hàng
    }
}