using Microsoft.EntityFrameworkCore;

namespace LangFood.Shared.Models
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
        // Mở file LangFoodDbContext.cs và thêm dòng này vào cùng các DbSet khác
        public DbSet<Category> Categories { get; set; }
        
        // Thêm DbSet cho Shop và Shipper
        public DbSet<Shop> Shops { get; set; }
        public DbSet<Shipper> Shippers { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Category>().HasQueryFilter(c => !c.IsDeleted);
            modelBuilder.Entity<Product>().HasQueryFilter(p => !p.IsDeleted);

            base.OnModelCreating(modelBuilder);
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
            modelBuilder.Entity<Shipper>().Property(s => s.WalletBalance).HasColumnType("decimal(18,2)");

            // 3. Cấu hình cụ thể mối quan hệ cho bảng Order (Buyer và Shipper)
            modelBuilder.Entity<Order>()
                .HasOne(o => o.Buyer)
                .WithMany(u => u.Orders)
                .HasForeignKey(o => o.BuyerId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.Shop)
                .WithMany(s => s.Orders)
                .HasForeignKey(o => o.ShopId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.Leg1Shipper)
                .WithMany(s => s.Leg1Orders)
                .HasForeignKey(o => o.Leg1ShipperId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Order>()
                .HasOne(o => o.Leg2Shipper)
                .WithMany(s => s.Leg2Orders)
                .HasForeignKey(o => o.Leg2ShipperId)
                .OnDelete(DeleteBehavior.Restrict);

            // 4. Cấu hình quan hệ 1-1 cho User - Shop
            modelBuilder.Entity<Shop>()
                .HasOne(s => s.User)
                .WithOne(u => u.Shop)
                .HasForeignKey<Shop>(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // 5. Cấu hình quan hệ 1-1 cho User - Shipper
            modelBuilder.Entity<Shipper>()
                .HasOne(s => s.User)
                .WithOne(u => u.Shipper)
                .HasForeignKey<Shipper>(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        }

    }
}