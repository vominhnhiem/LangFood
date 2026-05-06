using Microsoft.AspNetCore.Mvc;

namespace LangFoodAdmin.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
