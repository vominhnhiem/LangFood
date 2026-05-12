using Microsoft.AspNetCore.Mvc;

namespace LangFoodAdmin.Controllers
{
    public class ShippersController : Controller
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
