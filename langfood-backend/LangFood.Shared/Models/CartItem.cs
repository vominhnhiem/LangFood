using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using LangFood.Shared.Models;

public class CartItem
{
    [Key]
    public int Id { get; set; }
    public string UserId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }

    // --- THÊM 2 DÒNG NÀY ---
    public string? Note { get; set; } // Lời nhắn khách ghi
    public string? SelectedOptionsJson { get; set; } // Lưu danh sách ID option: "[1,5,8]"

    [ForeignKey("UserId")]
    public virtual User? User { get; set; }

    [ForeignKey("ProductId")]
    public virtual Product? Product { get; set; }
}