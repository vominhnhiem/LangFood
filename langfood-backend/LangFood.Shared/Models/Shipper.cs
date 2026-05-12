using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace LangFood.Shared.Models
{
    public class Shipper
    {
        [Key]
        public int Id { get; set; }

        public string UserId { get; set; } = string.Empty;

        public int? ActiveBuildingId { get; set; }

        public decimal WalletBalance { get; set; } = 0;

        public bool IsOnline { get; set; } = false;

        public bool IsApproved { get; set; } = false;

        [JsonIgnore]
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }

        [JsonIgnore]
        [InverseProperty("Leg1Shipper")]
        public virtual ICollection<Order> Leg1Orders { get; set; } = new List<Order>();

        [JsonIgnore]
        [InverseProperty("Leg2Shipper")]
        public virtual ICollection<Order> Leg2Orders { get; set; } = new List<Order>();
    }
}
