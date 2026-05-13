using LangFood.Shared.Models;
using System.Collections.Generic;

namespace LangFood.Shared.ViewModels
{
    public class ShipperManagementViewModel
    {
        public List<User> PendingShippers { get; set; } = new List<User>();
        public List<Shipper> ActiveShippers { get; set; } = new List<Shipper>();
    }
}
