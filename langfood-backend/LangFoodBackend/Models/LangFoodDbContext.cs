using Microsoft.EntityFrameworkCore;
using YourProjectName.Models;

namespace LangFoodBackend.Models
{
    public class LangFoodDbContext : DbContext
    {
        public LangFoodDbContext(DbContextOptions<LangFoodDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<UserReport> UserReports { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<RoleRequest> RoleRequests { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // 1. Fix lỗi 1785: Chặn xóa dây chuyền (Cascade) để SQL không báo lỗi Path cycles
            foreach (var relationship in modelBuilder.Model.GetEntityTypes().SelectMany(e => e.GetForeignKeys()))
            {
                relationship.DeleteBehavior = DeleteBehavior.NoAction;
            }

            // 2. Cấu hình kiểu dữ liệu tiền tệ (decimal) cho chuẩn SQL
            modelBuilder.Entity<Product>().Property(p => p.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Order>().Property(o => o.TotalAmount).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Order>().Property(o => o.ShippingFee).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<OrderItem>().Property(oi => oi.UnitPrice).HasColumnType("decimal(18,2)");

            // 3. Cấu hình cụ thể mối quan hệ cho bảng Order (Buyer và Shipper)
            modelBuilder.Entity<Order>()
                .HasOne(o => o.Buyer)
                .WithMany()
                .HasForeignKey(o => o.BuyerId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.Shipper)
                .WithMany()
                .HasForeignKey(o => o.ShipperId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.ExternalShipper)
                .WithMany()
                .HasForeignKey(o => o.ExternalShipperId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}