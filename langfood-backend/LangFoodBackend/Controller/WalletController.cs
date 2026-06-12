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

        // 1. LẤY THÔNG TIN VÍ
        // Nếu chưa có ví thì tự động tạo mới với số dư 0đ.
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

        // 2. GỬI YÊU CẦU NẠP TIỀN (Hoặc xác nhận đã chuyển khoản đơn hàng)
        // Tạo một giao dịch ở trạng thái "Chờ duyệt" (Status = 0) để Admin kiểm tra.
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
                // Nếu nạp cho đơn hàng thì ghi chú rõ mã đơn, nếu không thì ghi nạp tiền bình thường
                Description = orderId.HasValue ? $"Thanh toán đơn hàng #{orderId} qua QR" : "Yêu cầu nạp tiền vào ví",
                Status = 0, // Chờ Admin duyệt
                OrderId = orderId,
                CreatedAt = DateTime.Now
            };

            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Yêu cầu thanh toán đã được gửi tới Admin." });
        }

        // 3. ADMIN DUYỆT NẠP TIỀN
        // Khi Admin bấm nút Duyệt, tiền mới thực sự được cộng vào ví và đơn hàng mới được chuyển trạng thái.
        [HttpPost("approve-deposit/{transactionId}")]
        public async Task<IActionResult> ApproveDeposit(int transactionId)
        {
            var transaction = await _context.Transactions.FindAsync(transactionId);
            if (transaction == null || transaction.Status != 0) return BadRequest("Giao dịch không hợp lệ.");

            var wallet = await _context.Wallets.FindAsync(transaction.WalletId);
            if (wallet == null) return NotFound("Không tìm thấy ví");

            // BƯỚC 1: Cộng tiền vào số dư ví
            wallet.Balance += transaction.Amount;
            wallet.UpdatedAt = DateTime.Now;
            transaction.Status = 1; // Đánh dấu giao dịch thành công

            // BƯỚC 2: Nếu nạp để trả đơn hàng, thì đổi trạng thái đơn hàng luôn
            if (transaction.OrderId.HasValue)
            {
                var order = await _context.Orders.FindAsync(transaction.OrderId.Value);
                if (order != null && order.Status == "PendingPayment")
                {
                    // Chuyển từ "Chờ thanh toán" sang "Chờ xác nhận" để Quán thấy đơn
                    order.Status = "Pending";
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã duyệt nạp tiền thành công", newBalance = wallet.Balance });
        }

        // 4. XEM LỊCH SỬ GIAO DỊCH
        // Lấy tất cả các biến động tiền (Nạp, Rút, Nhận tiền...) của một người.
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

        // 5. GỬI YÊU CẦU RÚT TIỀN
        // Người dùng yêu cầu rút tiền về ngân hàng. 
        [HttpPost("withdrawal-request")]
        public async Task<IActionResult> CreateWithdrawalRequest([FromBody] WithdrawalRequestDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            var wallet = await _context.Wallets.FirstOrDefaultAsync(w => w.UserId == dto.UserId);

            // Kiểm tra tối thiểu 50k
            if (dto.Amount < 50000) return BadRequest("Số tiền rút tối thiểu là 50,000đ.");

            // Kiểm tra số dư: Quán ăn phải giữ lại ít nhất 1 triệu trong ví (ký quỹ)
            if (user.RoleId == 2)
            {
                if (wallet.Balance - dto.Amount < 1000000)
                    return BadRequest("Quán ăn phải duy trì số dư tối thiểu 1,000,000đ.");
            }
            else
            {
                if (wallet.Balance < dto.Amount) return BadRequest("Số dư không đủ.");
            }

            // TRỪ TIỀN LUÔN (Đóng băng tiền rút)
            wallet.Balance -= dto.Amount;
            wallet.UpdatedAt = DateTime.Now;

            // Tạo hồ sơ rút tiền để Admin thấy và chuyển khoản thủ công
            var request = new WithdrawalRequest
            {
                UserId = dto.UserId,
                Amount = dto.Amount,
                BankName = dto.BankName,
                BankAccountNumber = dto.BankAccountNumber,
                BankAccountName = dto.BankAccountName,
                Status = 0, // Đang chờ duyệt
                CreatedAt = DateTime.Now
            };

            // Ghi vào lịch sử giao dịch là đang rút tiền
            var transaction = new Transaction
            {
                WalletId = wallet.Id,
                Amount = -dto.Amount, // Số tiền âm
                Type = "WITHDRAW",
                Description = $"Rút tiền về {dto.BankName}",
                Status = 0,
                CreatedAt = DateTime.Now
            };

            _context.WithdrawalRequests.Add(request);
            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Gửi yêu cầu thành công.", newBalance = wallet.Balance });
        }

        // 6. XEM LỊCH SỬ RÚT TIỀN
        // Để người dùng xem hồ sơ rút tiền của mình Admin đã chuyển khoản chưa.
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