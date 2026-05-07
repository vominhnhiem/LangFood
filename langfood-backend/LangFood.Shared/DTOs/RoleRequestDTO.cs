using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LangFood.Shared.DTOs
{
    public class RoleRequestDTO
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public string FullName { get; set; } // Tên người gửi yêu cầu
        public int RequestType { get; set; } // 1: Bán hàng, 2: Shipper
        public string? ShopName { get; set; }
        public string? ShopAddress { get; set; }
        public string? ImageProof { get; set; } // Ảnh minh chứng (CCCD hoặc mặt bằng)
        public int Status { get; set; } // 0: Chờ, 1: Duyệt, 2: Từ chối
    }
}
