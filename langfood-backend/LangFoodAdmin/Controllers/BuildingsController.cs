using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.Models;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Authorization;

namespace LangFoodAdmin.Controllers
{
    [Authorize(Roles = "Admin")]
    public class BuildingsController : Controller
    {
        private readonly HttpClient _httpClient;
        private readonly string _apiUrl = "http://localhost:5289/api/buildings"; // Thay port đúng của Backend

        public BuildingsController(IHttpClientFactory httpClientFactory)
        {
            _httpClient = httpClientFactory.CreateClient();
        }

        // 1. Trang danh sách tòa nhà
        public async Task<IActionResult> Index()
        {
            var buildings = await _httpClient.GetFromJsonAsync<List<Building>>(_apiUrl);
            return View(buildings);
        }

        // 2. Trang thêm mới (Giao diện)
        public IActionResult Create()
        {
            return View();
        }

        // 3. Xử lý thêm mới
        [HttpPost]
        public async Task<IActionResult> Create(Building building)
        {
            if (ModelState.IsValid)
            {
                await _httpClient.PostAsJsonAsync(_apiUrl, building);
                TempData["SuccessMessage"] = "Thêm tòa nhà thành công!";
                return RedirectToAction(nameof(Index));
            }
            return View(building);
        }

        // 4. Trang chỉnh sửa
        public async Task<IActionResult> Edit(int id)
        {
            var building = await _httpClient.GetFromJsonAsync<Building>($"{_apiUrl}/{id}");
            if (building == null) return NotFound();
            return View(building);
        }

        [HttpPost]
        public async Task<IActionResult> Edit(int id, Building building)
        {
            await _httpClient.PutAsJsonAsync($"{_apiUrl}/{id}", building);
            TempData["SuccessMessage"] = "Cập nhật tòa nhà thành công!";
            return RedirectToAction(nameof(Index));
        }

        // 5. Xử lý xóa
        public async Task<IActionResult> Delete(int id)
        {
            var response = await _httpClient.DeleteAsync($"{_apiUrl}/{id}");
            if (!response.IsSuccessStatusCode)
            {
                // Có thể thêm thông báo lỗi nếu tòa nhà đang có sinh viên
                TempData["ErrorMessage"] = "Không thể xóa tòa nhà đang có sinh viên!";
            }
            else
            {
                TempData["SuccessMessage"] = "Đã xóa tòa nhà thành công!";
            }
            return RedirectToAction(nameof(Index));
        }
    }
}