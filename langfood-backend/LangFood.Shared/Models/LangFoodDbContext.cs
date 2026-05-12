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
        // ĐÃ XÓA UserReports ở đây
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<RoleRequest> RoleRequests { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<Shop> Shops { get; set; }
        public DbSet<Shipper> Shippers { get; set; }
        public DbSet<Building> Buildings { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Category>().HasQueryFilter(c => !c.IsDeleted);
            modelBuilder.Entity<Product>().HasQueryFilter(p => !p.IsDeleted);

            base.OnModelCreating(modelBuilder);

            // 1. Chặn xóa dây chuyền
            foreach (var relationship in modelBuilder.Model.GetEntityTypes().SelectMany(e => e.GetForeignKeys()))
            {
                relationship.DeleteBehavior = DeleteBehavior.NoAction;
            }

            // 2. Cấu hình decimal
            modelBuilder.Entity<Product>().Property(p => p.Price).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Order>().Property(o => o.TotalAmount).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Order>().Property(o => o.ShippingFee).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<OrderItem>().Property(oi => oi.UnitPrice).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Shipper>().Property(s => s.WalletBalance).HasColumnType("decimal(18,2)");
            modelBuilder.Entity<Shop>().Property(s => s.WalletBalance).HasColumnType("decimal(18,2)");

            // 3. Cấu hình quan hệ Order
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

            modelBuilder.Entity<Order>()
                .HasOne(o => o.Building)
                .WithMany()
                .HasForeignKey(o => o.BuildingId)
                .OnDelete(DeleteBehavior.NoAction);

            // 4. Cấu hình quan hệ 1-1
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
        }
    }
}