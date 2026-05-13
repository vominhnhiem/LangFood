using System.Collections.Generic;
using LangFood.Shared.Models;

namespace LangFood.Shared.ViewModels
{
    public class ShopManagementViewModel
    {
        public List<RoleRequest> PendingRequests { get; set; } = new List<RoleRequest>();
        public List<Shop> ActiveShops { get; set; } = new List<Shop>();
    }
}
