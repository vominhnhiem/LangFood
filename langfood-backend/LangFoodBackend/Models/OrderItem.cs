using System.Text.Json.Serialization; // Thêm dòng này
using System.ComponentModel.DataAnnotations.Schema;

namespace LangFoodBackend.Models
{
    public class OrderItem
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }

        [JsonIgnore] // THÊM DÒNG NÀY ĐỂ CHẶN VÒNG LẶP
        [ForeignKey("OrderId")]
        public virtual Order? Order { get; set; }

        [ForeignKey("ProductId")]
        public virtual Product? Product { get; set; }
    }
}