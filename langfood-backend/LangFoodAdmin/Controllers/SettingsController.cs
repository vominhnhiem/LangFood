using Microsoft.AspNetCore.Mvc;
using LangFoodAdmin.Models;
using System.IO;
using System.Text.Json;

using Microsoft.AspNetCore.Authorization;

namespace LangFoodAdmin.Controllers
{
    [Authorize(Roles = "Admin")]
    public class SettingsController : Controller
    {
        private readonly string _settingsFilePath = Path.Combine(Directory.GetCurrentDirectory(), "system_settings.json");

        [HttpGet]
        public IActionResult Index()
        {
            var model = new SettingsViewModel();

            if (System.IO.File.Exists(_settingsFilePath))
            {
                try
                {
                    string json = System.IO.File.ReadAllText(_settingsFilePath);
                    model = JsonSerializer.Deserialize<SettingsViewModel>(json) ?? new SettingsViewModel();
                }
                catch
                {
                    SetDefaultSettings(model);
                }
            }
            else
            {
                SetDefaultSettings(model);
            }

            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult Save(SettingsViewModel model)
        {
            if (ModelState.IsValid)
            {
                try
                {
                    string json = JsonSerializer.Serialize(model, new JsonSerializerOptions { WriteIndented = true });
                    System.IO.File.WriteAllText(_settingsFilePath, json);
                    TempData["SuccessMessage"] = "Lưu cài đặt thành công!";
                }
                catch (System.Exception ex)
                {
                    TempData["ErrorMessage"] = "Không thể lưu cài đặt: " + ex.Message;
                }
            }
            else
            {
                TempData["ErrorMessage"] = "Dữ liệu nhập vào không hợp lệ!";
            }

            return RedirectToAction(nameof(Index));
        }

        private void SetDefaultSettings(SettingsViewModel model)
        {
            model.CommissionRate = 10.0m;
            model.BaseShippingFee = 15000.0m;
            model.SystemAnnouncement = "Chào mừng đến với hệ thống Làng Food! Chúc quý khách ngon miệng!";
        }
    }
}
