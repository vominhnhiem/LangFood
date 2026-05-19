using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;
using LangFood.Shared.DTOs;

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

        // 2. API Nạp tiền (Gửi yêu cầu)
        [HttpPost("deposit")]
        public async Task<IActionResult> Deposit([FromQuery] string userId, [FromQuery] decimal amount, [FromQuery] int? orderId)
        {
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == userId);
            if (wallet == null) return NotFound("Không tìm thấy ví");

            var transaction = new Transaction
            {
                WalletId = wallet.Id,
                Amount = amount,
                Type = "DEPOSIT",
                Description = orderId.HasValue ? $"Thanh toán đơn hàng #{orderId} qua QR" : "Yêu cầu nạp tiền vào ví",
                Status = 0,
                OrderId = orderId,
                CreatedAt = DateTime.Now
            };

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Yêu cầu thanh toán đã được gửi tới Admin." });
        }

        // 3. API Duyệt nạp tiền (Dành cho Admin)
        [HttpPost("approve-deposit/{transactionId}")]
        public async Task<IActionResult> ApproveDeposit(int transactionId)
        {
            var transaction = await _context.Transactions.FindAsync(transactionId);
            if (transaction == null || transaction.Status != 0) return BadRequest("Giao dịch không hợp lệ.");

            var wallet = await _context.Wallets.FindAsync(transaction.WalletId);
            if (wallet == null) return NotFound("Không tìm thấy ví");

            wallet.Balance += transaction.Amount;
            wallet.UpdatedAt = DateTime.Now;
            transaction.Status = 1;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã duyệt nạp tiền thành công", newBalance = wallet.Balance });
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

        // 5. API Tạo yêu cầu rút tiền (Đã thêm ràng buộc số dư tối thiểu và số tiền rút tối thiểu)
        [HttpPost("withdrawal-request")]
        public async Task<IActionResult> CreateWithdrawalRequest([FromBody] WithdrawalRequestDto dto)
        {
            // Kiểm tra User để lấy RoleId
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user == null) return NotFound("Không tìm thấy người dùng.");

            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == dto.UserId);
            if (wallet == null) return NotFound("Không tìm thấy ví.");

            // QUY TẮC 1: Số tiền rút tối thiểu là 50,000đ
            if (dto.Amount < 50000)
            {
                return BadRequest("Số tiền rút tối thiểu là 50,000đ.");
            }

            // QUY TẮC 2: Đối với Quán ăn (RoleId = 2), số dư sau khi rút phải >= 1,000,000đ
            if (user.RoleId == 2)
            {
                if (wallet.Balance - dto.Amount < 1000000)
                {
                    return BadRequest("Quán ăn phải duy trì số dư tối thiểu 1,000,000đ trong ví.");
                }
            }
            else
            {
                // Đối với các vai trò khác (Shipper, Sinh viên), chỉ cần đủ số dư
                if (wallet.Balance < dto.Amount)
                {
                    return BadRequest("Số dư không đủ để thực hiện giao dịch.");
                }
            }

            // Thực hiện trừ tiền ngay (Đóng băng số tiền rút)
            wallet.Balance -= dto.Amount;
            wallet.UpdatedAt = DateTime.Now;

            // Tạo yêu cầu rút tiền
            var request = new WithdrawalRequest
            {
                UserId = dto.UserId,
                Amount = dto.Amount,
                BankName = dto.BankName,
                BankAccountNumber = dto.BankAccountNumber,
                BankAccountName = dto.BankAccountName,
                Note = dto.Note,
                Status = 0, // Chờ duyệt
                CreatedAt = DateTime.Now
            };

            // Tạo bản ghi giao dịch (Transaction)
            var transaction = new Transaction
            {
                WalletId = wallet.Id,
                Amount = -dto.Amount, // Số tiền âm
                Type = "WITHDRAW",
                Description = $"Rút tiền về {dto.BankName}",
                Status = 0, // Đang xử lý
                CreatedAt = DateTime.Now
            };

            _context.WithdrawalRequests.Add(request);
            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Gửi yêu cầu thành công.", newBalance = wallet.Balance });
        }

        // 6. Lấy lịch sử rút tiền
        [HttpGet("withdrawal-history/{userId}")]
        public async Task<IActionResult> GetWithdrawalHistory(string userId)
        {
            var history = await _context.WithdrawalRequests
                .Where(w => w.UserId == userId)
                .OrderByDescending(w => w.CreatedAt)
                .ToListAsync();
            return Ok(history);
        }
    }
}