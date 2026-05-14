using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System.Collections.Generic;
using System.Linq;
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

        // 1. LẤY TẤT CẢ TÒA NHÀ (Đã tối ưu Select để chạy nhanh và tránh lỗi 500)
        [HttpGet]
        public async Task<ActionResult> GetBuildings()
        {
            try
            {
                var buildings = await _context.Buildings
                    .OrderBy(b => b.Name)
                    .Select(b => new {
                        b.Id,
                        b.Name,
                        b.IsActive
                    })
                    .ToListAsync();

                return Ok(buildings);
            }
            catch (System.Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách tòa nhà: " + ex.Message });
            }
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
            if (!ModelState.IsValid) return BadRequest(ModelState);

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
                return Ok(new { message = "Cập nhật thành công!", data = building });
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!_context.Buildings.Any(e => e.Id == id))
                {
                    return NotFound(new { message = "Không tìm thấy tòa nhà." });
                }
                else
                {
                    throw;
                }
            }
        }

        // 5. XÓA TÒA NHÀ (Dành cho Admin)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteBuilding(int id)
        {
            var building = await _context.Buildings.FindAsync(id);
            if (building == null)
            {
                return NotFound(new { message = "Tòa nhà không tồn tại." });
            }

            // Kiểm tra ràng buộc: Nếu có sinh viên đang ở thì không cho xóa
            bool hasUsers = await _context.Users.AnyAsync(u => u.BuildingId == id);
            if (hasUsers)
            {
                return BadRequest(new { message = "Không thể xóa vì đang có sinh viên đăng ký ở tòa này!" });
            }

            _context.Buildings.Remove(building);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã xóa tòa nhà thành công." });
        }
    }
}