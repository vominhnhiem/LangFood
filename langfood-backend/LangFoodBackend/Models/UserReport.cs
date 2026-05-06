using System;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFoodBackend.Models
{
    public class UserReport
    {
        public int Id { get; set; }
        public string ReporterId { get; set; } = string.Empty;
        public string ReportedUserId { get; set; } = string.Empty;
        public int OrderId { get; set; }
        public string Reason { get; set; } = string.Empty;
        public string Status { get; set; } = "Open";
        public string? AdminResolutionNote { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? ResolvedAt { get; set; }

        [ForeignKey("ReporterId")]
        public virtual User? Reporter { get; set; }

        [ForeignKey("ReportedUserId")]
        public virtual User? ReportedUser { get; set; }

        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }
    }
}