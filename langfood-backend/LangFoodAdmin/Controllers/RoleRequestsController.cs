using Microsoft.AspNetCore.Mvc;
using LangFood.Shared.DTOs;
using System.Net.Http.Json;

namespace LangFoodAdmin.Controllers
{
    // Đây là Controller của trang WEB Admin (MVC), không phải API
    public class RoleRequestsController : Controller
    {
        private readonly HttpClient _httpClient;

        public RoleRequestsController(IHttpClientFactory httpClientFactory)
        {
            // "BackendApi" đã được cấu hình trong Program.cs của Admin
            _httpClient = httpClientFactory.CreateClient("BackendApi");
        }

        // 1. Trang hiển thị danh sách yêu cầu chờ duyệt (HÀM NÀY ĐỂ VẼ GIAO DIỆN)
        public async Task<IActionResult> Index()
        {
            try
            {
                // Gọi sang Backend để lấy dữ liệu
                var requests = await _httpClient.GetFromJsonAsync<List<RoleRequestDTO>>("api/AdminApi/pending-role-requests");
                return View(requests ?? new List<RoleRequestDTO>());
            }
            catch (Exception ex)
            {
                // Nếu Backend chưa chạy hoặc lỗi cổng (Port) sẽ nhảy vào đây
                return View(new List<RoleRequestDTO>());
            }
        }

        // 2. Xử lý khi Admin nhấn nút "Duyệt" trên Web
        public async Task<IActionResult> Approve(int id)
        {
            try
            {
                var response = await _httpClient.PostAsync($"api/AdminApi/approve-role-request/{id}", null);

                if (response.IsSuccessStatusCode)
                {
                    TempData["Success"] = "Đã duyệt quyền thành công!";
                }
                else
                {
                    TempData["Error"] = "Lỗi hệ thống khi duyệt.";
                }
            }
            catch (Exception ex)
            {
                TempData["Error"] = "Không thể kết nối tới Backend!";
            }

            return RedirectToAction(nameof(Index));
        }
    }
}