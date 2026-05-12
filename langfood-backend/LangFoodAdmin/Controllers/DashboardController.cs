using Microsoft.AspNetCore.Mvc;

namespace LangFoodAdmin.Controllers
{
    public class DashboardController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
