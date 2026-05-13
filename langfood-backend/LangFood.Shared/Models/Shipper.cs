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


        public bool IsOnline { get; set; } = false;

        public bool IsApproved { get; set; } = false;

        [JsonIgnore]
        [ForeignKey("UserId")]
        public virtual User? User { get; set; }

        // THAY THẾ Leg1Orders và Leg2Orders bằng 1 danh sách duy nhất
        [JsonIgnore]
        [InverseProperty("Shipper")]
        public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
    }
}