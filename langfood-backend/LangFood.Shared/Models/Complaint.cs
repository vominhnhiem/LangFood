using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class Complaint
    {
        [Key]
        public int Id { get; set; }
        
        public int OrderId { get; set; }
        
        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }
        
        [Required]
        public string Reason { get; set; } = string.Empty;
        
        [Required]
        public string Detail { get; set; } = string.Empty;
        
        public string? ImageProof { get; set; }
        
        public int Status { get; set; } = 0; // 0: Pending, 1: Resolved, 2: Rejected
        
        public string? AdminReply { get; set; }
        
        public decimal PenaltyAmount { get; set; } = 0;
        
        public DateTime CreatedAt { get; set; } = DateTime.Now;
        
        public DateTime? ResolvedAt { get; set; }
    }
}
