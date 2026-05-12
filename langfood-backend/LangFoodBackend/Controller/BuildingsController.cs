using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace LangFoodBackend.Controller
{
    [Route("api/[controller]")]
    [ApiController]
    public class BuildingsController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public BuildingsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. LẤY TẤT CẢ TÒA NHÀ (Dùng cho cả Admin và Mobile Spinner)
        // Mobile nên gọi cái này để hiện danh sách chọn
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Building>>> GetBuildings()
        {
            return await _context.Buildings
                .OrderBy(b => b.Name)
                .ToListAsync();
        }

        // 2. LẤY CHI TIẾT 1 TÒA NHÀ
        [HttpGet("{id}")]
        public async Task<ActionResult<Building>> GetBuilding(int id)
        {
            var building = await _context.Buildings.FindAsync(id);

            if (building == null)
            {
                return NotFound(new { message = "Không tìm thấy tòa nhà này." });
            }

            return building;
        }

        // 3. THÊM TÒA NHÀ MỚI (Dành cho Admin)
        [HttpPost]
        public async Task<ActionResult<Building>> PostBuilding(Building building)
        {
            _context.Buildings.Add(building);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetBuilding", new { id = building.Id }, building);
        }

        // 4. CẬP NHẬT TÒA NHÀ (Dành cho Admin)
        [HttpPut("{id}")]
        public async Task<IActionResult> PutBuilding(int id, Building building)
        {
            if (id != building.Id)
            {
                return BadRequest(new { message = "ID không khớp." });
            }

            _context.Entry(building).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!BuildingExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return Ok(new { message = "Cập nhật thành công!", data = building });
        }

        // 5. XÓA TÒA NHÀ (Dành cho Admin)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteBuilding(int id)
        {
            var building = await _context.Buildings.FindAsync(id);
            if (building == null)
            {
                return NotFound();
            }

            // Kiểm tra xem có User nào đang ở tòa này không trước khi xóa
            bool hasUsers = await _context.Users.AnyAsync(u => u.BuildingId == id);
            if (hasUsers)
            {
                return BadRequest(new { message = "Không thể xóa vì đang có sinh viên đăng ký ở tòa này!" });
            }

            _context.Buildings.Remove(building);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa tòa nhà thành công." });
        }

        private bool BuildingExists(int id)
        {
            return _context.Buildings.Any(e => e.Id == id);
        }
    }
}