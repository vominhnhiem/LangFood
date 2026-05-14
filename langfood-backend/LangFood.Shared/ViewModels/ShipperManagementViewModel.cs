using LangFood.Shared.Models;
using System.Collections.Generic;

namespace LangFood.Shared.ViewModels
{
    public class ShipperManagementViewModel
    {
        // Phải là List<RoleRequest> để lấy được thông tin từ bảng yêu cầu
        public List<RoleRequest> PendingShippers { get; set; } = new List<RoleRequest>();

        // Danh sách shipper đã hoạt động
        public List<Shipper> ActiveShippers { get; set; } = new List<Shipper>();
    }
}