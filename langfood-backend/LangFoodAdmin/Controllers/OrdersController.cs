using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using System.Collections.Generic;

namespace LangFoodAdmin.Controllers
{
    public class OrdersController : Controller
    {
        public IActionResult Index()
        {
            // Simulate fetching dormitories from database
            var dormitories = new List<string> { "AH1", "AH2", "BA1", "BA2", "BA3", "BA4" };
            ViewBag.Dormitories = new SelectList(dormitories);
            
            return View();
        }
    }
}
