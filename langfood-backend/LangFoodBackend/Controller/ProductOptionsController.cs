using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace LangFoodBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductOptionsController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public ProductOptionsController(LangFoodDbContext context)
        {
            _context = context;
        }

        // --- 1. LẤY DANH SÁCH TOPPING CỦA 1 MÓN ĂN ---
        [HttpGet("product/{productId}")]
        public async Task<ActionResult<IEnumerable<ProductOptionGroup>>> GetOptionsByProduct(int productId)
        {
            return await _context.ProductOptionGroups
                .Include(g => g.Options)
                .Where(g => g.ProductId == productId)
                .ToListAsync();
        }

        // --- 2. QUẢN LÝ NHÓM TOPPING (GROUP) ---

        // Thêm nhóm mới (VD: "Chọn size", "Thêm Topping")
        [HttpPost("group")]
        public async Task<ActionResult<ProductOptionGroup>> CreateGroup(ProductOptionGroup group)
        {
            _context.ProductOptionGroups.Add(group);
            await _context.SaveChangesAsync();
            return Ok(group);
        }

        // Cập nhật tên nhóm hoặc ràng buộc (Min/Max Selectable)
        [HttpPut("group/{id}")]
        public async Task<IActionResult> UpdateGroup(int id, ProductOptionGroup updatedGroup)
        {
            if (id != updatedGroup.Id) return BadRequest("ID không khớp");

            _context.Entry(updatedGroup).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!_context.ProductOptionGroups.Any(e => e.Id == id)) return NotFound();
                throw;
            }

            return Ok(updatedGroup);
        }

        // Xóa nhóm (Sẽ xóa luôn các Option bên trong do ràng buộc khóa ngoại)
        [HttpDelete("group/{id}")]
        public async Task<IActionResult> DeleteGroup(int id)
        {
            var group = await _context.ProductOptionGroups.FindAsync(id);
            if (group == null) return NotFound();

            _context.ProductOptionGroups.Remove(group);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xóa nhóm Topping thành công" });
        }

        // --- 3. QUẢN LÝ LỰA CHỌN CHI TIẾT (OPTION) ---

        // Thêm một lựa chọn vào nhóm (VD: Thêm "Trứng" vào nhóm "Topping")
        [HttpPost("option")]
        public async Task<ActionResult<ProductOption>> CreateOption(ProductOption option)
        {
            // Lưu ý: Đảm bảo Model ProductOption có trường AdditionalPrice
            _context.ProductOptions.Add(option);
            await _context.SaveChangesAsync();
            return Ok(option);
        }

        // Cập nhật tên Option hoặc Giá cộng thêm (AdditionalPrice)
        [HttpPut("option/{id}")]
        public async Task<IActionResult> UpdateOption(int id, ProductOption updatedOption)
        {
            if (id != updatedOption.Id) return BadRequest("ID không khớp");

            // Đảm bảo cập nhật giá đúng vào cột AdditionalPrice
            var existingOption = await _context.ProductOptions.FindAsync(id);
            if (existingOption == null) return NotFound();

            existingOption.Name = updatedOption.Name;
            existingOption.AdditionalPrice = updatedOption.AdditionalPrice;
            existingOption.IsAvailable = updatedOption.IsAvailable;
            existingOption.OptionGroupId = updatedOption.OptionGroupId;

            await _context.SaveChangesAsync();
            return Ok(existingOption);
        }

        // Xóa một lựa chọn
        [HttpDelete("option/{id}")]
        public async Task<IActionResult> DeleteOption(int id)
        {
            var option = await _context.ProductOptions.FindAsync(id);
            if (option == null) return NotFound();

            _context.ProductOptions.Remove(option);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xóa lựa chọn thành công" });
        }
    }
}