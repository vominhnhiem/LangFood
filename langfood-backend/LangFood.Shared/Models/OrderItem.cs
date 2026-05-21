using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;
using LangFood.Shared.Models;

public class OrderItem
{
    public int Id { get; set; }
    public int OrderId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }

    // --- THÊM 3 DÒNG NÀY ---
    public string? Note { get; set; }
    public string? OptionsSummary { get; set; } // VD: "Topping: Thêm trứng, Tóp mỡ"
    public decimal OptionsPrice { get; set; } // Tổng tiền topping

    [JsonIgnore]
    [ForeignKey("OrderId")]
    public virtual Order? Order { get; set; }

    [ForeignKey("ProductId")]
    public virtual Product? Product { get; set; }
}