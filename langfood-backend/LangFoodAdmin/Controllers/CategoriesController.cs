using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.DTOs;

namespace LangFoodAdmin.Controllers
{
    public class CategoriesController : Controller
    {
        private readonly HttpClient _httpClient;

        public CategoriesController(IHttpClientFactory factory)
        {
            _httpClient = factory.CreateClient("BackendApi");
        }

        // 1. Danh sách danh mục
        public async Task<IActionResult> Index()
        {
            var list = await _httpClient.GetFromJsonAsync<List<CategoryDTO>>("api/Categories");
            return View(list ?? new List<CategoryDTO>());
        }

        [HttpGet]
        public IActionResult Create()
        {
            return View();
        }
        // 2. Giao diện thêm mới
        [HttpPost]
        public async Task<IActionResult> Create(string name, IFormFile imageFile)
        {
            using var content = new MultipartFormDataContent();
            content.Add(new StringContent(name), "name");

            if (imageFile != null)
            {
                var fileStream = imageFile.OpenReadStream();
                var fileContent = new StreamContent(fileStream);
                fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(imageFile.ContentType);
                content.Add(fileContent, "image", imageFile.FileName);
            }

            // Gọi đến API upload mới tạo ở Bước 1
            var response = await _httpClient.PostAsync("api/Categories/upload", content);

            if (response.IsSuccessStatusCode) return RedirectToAction(nameof(Index));
            return View();
        }

        // 3. Giao diện chỉnh sửa
        public async Task<IActionResult> Edit(int id)
        {
            var category = await _httpClient.GetFromJsonAsync<CategoryDTO>($"api/Categories/{id}");
            return View(category);
        }

        [HttpPost]
        public async Task<IActionResult> Edit(CategoryDTO category)
        {
            await _httpClient.PutAsJsonAsync($"api/Categories/{category.Id}", category);
            return RedirectToAction(nameof(Index));
        }

        // 4. Xóa
        public async Task<IActionResult> Delete(int id)
        {
            await _httpClient.DeleteAsync($"api/Categories/{id}");
            return RedirectToAction(nameof(Index));
        }
    }
}