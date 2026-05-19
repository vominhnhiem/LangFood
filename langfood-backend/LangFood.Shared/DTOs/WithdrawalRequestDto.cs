using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace LangFood.Shared.DTOs
{
    public class WithdrawalRequestDto
    {
        public string UserId { get; set; }
        public decimal Amount { get; set; }
        public string BankName { get; set; }
        public string BankAccountNumber { get; set; }
        public string BankAccountName { get; set; }
        public string? Note { get; set; }
    }
                
}
