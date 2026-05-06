using Microsoft.AspNetCore.Mvc;

namespace LangFoodDB.Controllers
{
    public class AdminController : Controller
    {
        // Require role Admin (nếu đã có config Auth, có thể thêm [Authorize(Roles = "Admin")])
        public IActionResult PendingRequests()
        {
            return View();
        }
    }
}
