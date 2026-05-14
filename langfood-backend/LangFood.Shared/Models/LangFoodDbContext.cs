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

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // 1. Cấu hình kiểu dữ liệu decimal (Tránh sai số tiền tệ)
            modelBuilder.Entity<Wallet>().Property(w => w.Balance).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Transaction>().Property(t => t.Amount).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Product>().Property(p => p.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Order>().Property(o => o.TotalAmount).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Order>().Property(o => o.ShippingFee).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<OrderItem>().Property(oi => oi.UnitPrice).HasColumnType("decimal(18,2)");

            // 2. Query Filters (Xử lý xóa mềm)
            modelBuilder.Entity<Category>().HasQueryFilter(c => !c.IsDeleted);
            modelBuilder.Entity<Product>().HasQueryFilter(p => !p.IsDeleted);

            // 3. Chặn xóa dây chuyền mặc định (No Action)
            foreach (var relationship in modelBuilder.Model.GetEntityTypes().SelectMany(e => e.GetForeignKeys()))
            {
                relationship.DeleteBehavior = DeleteBehavior.NoAction;
            }

            // 4. Cấu hình quan hệ Order
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

            // 6. CẤU HÌNH VÍ (WALLET) - Quan hệ 1-1 với User
            modelBuilder.Entity<Wallet>()
                .HasOne(w => w.User)
                .WithOne(u => u.Wallet)
                .HasForeignKey<Wallet>(w => w.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            // 7. CẤU HÌNH QUAN HỆ WALLET -> TRANSACTION (CHỈ ĐỊNH RÕ NAVIGATION)
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.Wallet) // Map vào thuộc tính Wallet trong class Transaction
                .WithMany()
                .HasForeignKey(t => t.WalletId)
                .OnDelete(DeleteBehavior.NoAction);

            // 8. CẤU HÌNH QUAN HỆ TRANSACTION -> ORDER (ĐỂ ĐỐI SOÁT)
            modelBuilder.Entity<Transaction>()
                .HasOne(t => t.Order) // Map vào thuộc tính Order trong class Transaction
                .WithMany(o => o.Transactions) // Map vào danh sách Transactions trong class Order
                .HasForeignKey(t => t.OrderId)
                .IsRequired(false)
                .OnDelete(DeleteBehavior.NoAction);
        }
    }
}
