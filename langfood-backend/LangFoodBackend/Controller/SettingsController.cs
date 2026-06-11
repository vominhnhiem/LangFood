using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models; // Đảm bảo namespace này khớp với project của bạn
using System.Threading.Tasks;

namespace LangFoodBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SettingsController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public SettingsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // GET: api/Settings
        // Endpoint này để App Android lấy cấu hình hệ thống
        [HttpGet]
        public async Task<ActionResult<SystemSetting>> GetSettings()
        {
            var setting = await _context.SystemSettings.FirstOrDefaultAsync();

            if (setting == null)
            {
                // Nếu chưa có cấu hình trong DB, trả về mặc định để app không bị crash
                return Ok(new SystemSetting
                {
                    IsMaintenanceMode = false,
                    BroadcastMessage = "Chào mừng quý khách đến với Làng Food!",
                    MaxOrderPerShipper = 3
                });
            }

            return Ok(setting);
        }
    }
}