using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace LangFoodAdmin.Controllers
{
    public class OrdersController : Controller
    {
        private readonly LangFoodDbContext _context;

        public OrdersController(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index(int? buildingId)
        {
            // 1. Lấy danh sách tòa nhà cho bộ lọc dropdown (Lấy tất cả để có thể lọc đơn cũ)
            var buildings = await _context.Buildings.ToListAsync();
            ViewBag.BuildingList = new SelectList(buildings, "Id", "Name", buildingId);

            // 2. Truy vấn danh sách đơn hàng kèm theo thông tin tòa nhà
            IQueryable<Order> query = _context.Orders
                .Include(o => o.Building)
                .Include(o => o.Shop)
                .OrderByDescending(o => o.CreatedAt);

            // 3. Thực hiện lọc nếu có chọn tòa nhà
            if (buildingId.HasValue)
            {
                query = query.Where(o => o.BuildingId == buildingId);
            }

            var orders = await query.ToListAsync();
            return View(orders);
        }
    }
}
