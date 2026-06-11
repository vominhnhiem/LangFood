using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFoodAdmin.Models;
using System.Threading.Tasks;
using System;

namespace LangFoodAdmin.Controllers
{
    public class SettingsController : Controller
    {
        private readonly LangFoodDbContext _context;

        public SettingsController(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            // Lấy cấu hình đầu tiên (hoặc tạo mới nếu chưa tồn tại)
            var setting = await _context.SystemSettings.FirstOrDefaultAsync();
            if (setting == null)
            {
                setting = new SystemSetting
                {
                    IsMaintenanceMode = false,
                    BroadcastMessage = "Chào mừng quý khách đến với Làng Food! Chúc quý khách ngon miệng!",
                    MaxOrderPerShipper = 3
                };
                _context.SystemSettings.Add(setting);
                await _context.SaveChangesAsync();
            }

            var model = new SettingsViewModel
            {
                IsMaintenanceMode = setting.IsMaintenanceMode,
                BroadcastMessage = setting.BroadcastMessage,
                MaxOrderPerShipper = setting.MaxOrderPerShipper
            };

            return View(model);
        }

        [HttpPost]
        public async Task<IActionResult> SaveSettings(SettingsViewModel model)
        {
            var setting = await _context.SystemSettings.FirstOrDefaultAsync();
            if (setting == null)
            {
                setting = new SystemSetting
                {
                    IsMaintenanceMode = model.IsMaintenanceMode,
                    BroadcastMessage = model.BroadcastMessage ?? string.Empty,
                    MaxOrderPerShipper = model.MaxOrderPerShipper
                };
                _context.SystemSettings.Add(setting);
            }
            else
            {
                setting.IsMaintenanceMode = model.IsMaintenanceMode;
                setting.BroadcastMessage = model.BroadcastMessage ?? string.Empty;
                setting.MaxOrderPerShipper = model.MaxOrderPerShipper;
            }

            // Ghi nhật ký hệ thống
            var log = new SystemLog
            {
                Content = $"Cấu hình vận hành hệ thống đã được cập nhật bởi Admin.",
                LogType = LogType.System,
                CreatedAt = DateTime.Now
            };
            _context.SystemLogs.Add(log);

            await _context.SaveChangesAsync();

            return Json(new { success = true, message = "Đã cập nhật cấu hình vận hành thành công!" });
        }
    }
}
