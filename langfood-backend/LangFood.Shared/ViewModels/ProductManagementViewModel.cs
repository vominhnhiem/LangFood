using LangFood.Shared.Models;
using System.Collections.Generic;

namespace LangFood.Shared.ViewModels
{
    public class ProductManagementViewModel
    {
        public List<Product> PendingProducts { get; set; } = new List<Product>();
        public List<Product> ActiveProducts { get; set; } = new List<Product>();
        public List<Category> Categories { get; set; } = new List<Category>();
        public List<Shop> Shops { get; set; } = new List<Shop>();
    }
}
