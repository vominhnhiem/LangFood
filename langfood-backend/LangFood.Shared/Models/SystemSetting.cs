using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFood.Shared.Models
{
    public class SystemSetting
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        public bool IsMaintenanceMode { get; set; } = false;

        [Required]
        public string BroadcastMessage { get; set; } = string.Empty;

        public int MaxOrderPerShipper { get; set; } = 3;
    }
}
