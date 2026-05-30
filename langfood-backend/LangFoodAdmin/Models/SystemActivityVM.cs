using System;

namespace LangFoodAdmin.Models
{
    public class SystemActivityVM
    {
        public string Message { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public string Type { get; set; } = string.Empty; // Success, Warning, Danger
    }
}
