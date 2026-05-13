using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;

namespace LangFoodBackend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class WalletController : ControllerBase
    {
        private readonly LangFoodDbContext _context;

        public WalletController(LangFoodDbContext context)
        {
            _context = context;
        }

        // 1. Lấy thông tin ví
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<Wallet>> GetWallet(string userId)
        {
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == userId);
            if (wallet == null)
            {
                wallet = new Wallet { UserId = userId, Balance = 0, UpdatedAt = DateTime.Now };
                _context.Wallets.Add(wallet);
                await _context.SaveChangesAsync();
            }
            return Ok(wallet);
        }

        // 2. API Nạp tiền (Người dùng gửi yêu cầu thông báo đã chuyển khoản)
        [HttpPost("deposit")]
        public async Task<IActionResult> Deposit([FromQuery] string userId, [FromQuery] decimal amount)
        {
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == userId);
            if (wallet == null) return NotFound("Không tìm thấy ví");

            // LƯU Ý: KHÔNG cộng tiền vào wallet.Balance ở đây.
            // Chỉ tạo bản ghi giao dịch ở trạng thái Pending (Status = 0)
            var transaction = new Transaction
            {
                WalletId = wallet.Id,
                Amount = amount,
                Type = "DEPOSIT",
                Description = "Yêu cầu nạp tiền qua VietQR",
                Status = 0, // Đang chờ duyệt
                CreatedAt = DateTime.Now
            };

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Yêu cầu nạp tiền đã được ghi nhận, vui lòng chờ Admin duyệt." });
        }

        // 3. API Dành cho Admin Duyệt nạp tiền (MỚI)
        [HttpPost("approve-deposit/{transactionId}")]
        public async Task<IActionResult> ApproveDeposit(int transactionId)
        {
            var transaction = await _context.Transactions.FindAsync(transactionId);
            if (transaction == null || transaction.Status != 0) return BadRequest("Giao dịch không hợp lệ hoặc đã được xử lý.");

            var wallet = await _context.Wallets.FindAsync(transaction.WalletId);
            if (wallet == null) return NotFound("Không tìm thấy ví");

            // 1. Cập nhật số dư ví
            wallet.Balance += transaction.Amount;
            wallet.UpdatedAt = DateTime.Now;

            // 2. Cập nhật trạng thái giao dịch thành công
            transaction.Status = 1;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã duyệt và cộng tiền thành công", newBalance = wallet.Balance });
        }

        // 4. Lấy lịch sử giao dịch
        [HttpGet("transactions/{userId}")]
        public async Task<ActionResult<IEnumerable<Transaction>>> GetTransactions(string userId)
        {
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == userId);
            if (wallet == null) return NotFound();

            return await _context.Transactions
                .Where(t => t.WalletId == wallet.Id)
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();
        }

        // 5. API Rút tiền
        [HttpPost("withdraw")]
        public async Task<IActionResult> Withdraw([FromQuery] string userId, [FromQuery] decimal amount, [FromQuery] string note)
        {
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == userId);
            if (wallet == null || wallet.Balance < amount) return BadRequest("Số dư không đủ");

            wallet.Balance -= amount;
            wallet.UpdatedAt = DateTime.Now;

            var transaction = new Transaction
            {
                WalletId = wallet.Id,
                Amount = amount,
                Type = "WITHDRAW",
                Description = "Rút tiền: " + note,
                Status = 1, // Giả sử rút tiền thì trừ luôn
                CreatedAt = DateTime.Now
            };

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Rút tiền thành công", newBalance = wallet.Balance });
        }
    }
}