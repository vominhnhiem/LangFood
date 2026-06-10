using System.Linq;
using Microsoft.EntityFrameworkCore;
using LangFood.Shared.Models;

namespace LangFood.Shared.Models
{
    public class LangFoodDbContext : DbContext
    {
        public LangFoodDbContext(DbContextOptions<LangFoodDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderItem> OrderItems { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<RoleRequest> RoleRequests { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Shop> Shops { get; set; }
        public DbSet<Shipper> Shippers { get; set; }
        public DbSet<Building> Buildings { get; set; }
        public DbSet<Wallet> Wallets { get; set; }
        public DbSet<Transaction> Transactions { get; set; }
        public DbSet<WithdrawalRequest> WithdrawalRequests { get; set; }
        public DbSet<SystemLog> SystemLogs { get; set; }
        // Thêm 2 dòng này vào trong class LangFoodDbContext
        public DbSet<ProductOptionGroup> ProductOptionGroups { get; set; }
        public DbSet<ProductOption> ProductOptions { get; set; }

        // Thêm cấu hình decimal vào trong hàm OnModelCreating
      

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // 1. Cấu hình kiểu dữ liệu decimal (Tránh sai số tiền tệ cho tất cả các bảng liên quan)
            modelBuilder.Entity<ProductOption>().Property(p => p.AdditionalPrice).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<OrderItem>().Property(oi => oi.OptionsPrice).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Wallet>().Property(w => w.Balance).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Transaction>().Property(t => t.Amount).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Product>().Property(p => p.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Order>().Property(o => o.TotalAmount).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Order>().Property(o => o.ShippingFee).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<OrderItem>().Property(oi => oi.UnitPrice).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<WithdrawalRequest>().Property(w => w.Amount).HasColumnType("decimal(18,2)");

            // 2. Query Filters (Xử lý xóa mềm)
            modelBuilder.Entity<Category>().HasQueryFilter(c => !c.IsDeleted);
            modelBuilder.Entity<Product>().HasQueryFilter(p => !p.IsDeleted);

            // 3. Chặn xóa dây chuyền mặc định (No Action)
            foreach (var relationship in modelBuilder.Model.GetEntityTypes().SelectMany(e => e.GetForeignKeys()))
            {
                relationship.DeleteBehavior = DeleteBehavior.NoAction;
            }

            // 4. Cấu hình thực thể Order
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
                .HasOne(o => o.Shipper)
                .WithMany(s => s.Orders)
                .HasForeignKey(o => o.ShipperId)
                .OnDelete(DeleteBehavior.Restrict);

            // --- THÊM CẤU HÌNH CHO SỐ ĐIỆN THOẠI NHẬN HÀNG ---
            modelBuilder.Entity<Order>()
                .Property(o => o.DeliveryPhone)
                .HasMaxLength(20);

            // 5. Cấu hình quan hệ 1-1 (Shop, Shipper)
            modelBuilder.Entity<Shop>()
                .HasOne(s => s.User)
                .WithOne(u => u.Shop)
                .HasForeignKey<Shop>(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Shipper>()
                .HasOne(s => s.User)
                .WithOne(u => u.Shipper)
                .HasForeignKey<Shipper>(s => s.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // 6. Cấu hình VÍ (WALLET)
            modelBuilder.Entity<Wallet>()
                .HasOne(w => w.User)
                .WithOne(u => u.Wallet)
                .HasForeignKey<Wallet>(w => w.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // 7. Cấu hình TRANSACTION
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.Wallet)
                .WithMany()
                .HasForeignKey(t => t.WalletId)
                .OnDelete(DeleteBehavior.NoAction);

            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.Order)
                .WithMany(o => o.Transactions)
                .HasForeignKey(t => t.OrderId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.NoAction);

            // 8. Cấu hình WITHDRAWAL REQUEST
            modelBuilder.Entity<WithdrawalRequest>()
                .HasOne(w => w.User)
                .WithMany()
                .HasForeignKey(w => w.UserId)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}