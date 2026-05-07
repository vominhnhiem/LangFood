using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.DTOs;

namespace LangFoodAdmin.Controllers
{
    public class ProductsController : Controller
    {
        private readonly HttpClient _httpClient;

        public ProductsController(IHttpClientFactory factory)
        {
            _httpClient = factory.CreateClient("BackendApi");
        }

        // Trang danh sách món chờ duyệt
        public async Task<IActionResult> Index()
        {
            var products = await _httpClient.GetFromJsonAsync<List<ProductDTO>>("api/AdminApi/pending-products");
            return View(products ?? new List<ProductDTO>());
        }

        // Action Duyệt món
        public async Task<IActionResult> Approve(int id)
        {
            var response = await _httpClient.PostAsync($"api/AdminApi/approve-product/{id}", null);
            if (response.IsSuccessStatusCode) TempData["Msg"] = "Đã duyệt món!";
            return RedirectToAction(nameof(Index));
        }
    }
}