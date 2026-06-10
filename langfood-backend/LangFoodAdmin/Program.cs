using LangFood.Shared;
using LangFood.Shared.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Authorization;

var builder = WebApplication.CreateBuilder(args);

// 1. Thêm dịch vụ cho giao diện MVC (Controllers và Views) kèm bộ lọc xác thực toàn cục
builder.Services.AddControllersWithViews(options =>
{
    var policy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
    options.Filters.Add(new AuthorizeFilter(policy));
});

// Thêm dịch vụ xác thực bằng Cookie
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.AccessDeniedPath = "/Account/Login";
        options.ExpireTimeSpan = TimeSpan.FromHours(2);
    });

builder.Services.AddSignalR();

// 2. CẤU HÌNH HTTPCLIENT: Đây là "số điện thoại" để Admin gọi sang Backend
builder.Services.AddHttpClient("BackendApi", client =>
{
    // Sử dụng cổng 5289 theo đúng cấu hình desiredPort trong file Program.cs của Backend
    client.BaseAddress = new Uri("http://localhost:5289/");

    // Cấu hình mặc định để làm việc với JSON
    client.DefaultRequestHeaders.Add("Accept", "application/json");
});

// 3. Đăng ký DbContext (Phòng trường hợp bạn vẫn muốn dùng trực tiếp một số bảng từ Shared)
builder.Services.AddDbContext<LangFoodDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

var app = builder.Build();

// Tự động seed tài khoản Admin gốc (Super Admin) nếu chưa tồn tại
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<LangFoodDbContext>();
    try
    {
        var rootAdminEmail = "admin@langfood.vn";
        var rootAdmin = context.Users.FirstOrDefault(u => u.Email == rootAdminEmail || u.Username == "admin");
        if (rootAdmin == null)
        {
            using (var sha256 = System.Security.Cryptography.SHA256.Create())
            {
                var bytes = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes("admin"));
                var passwordHash = Convert.ToHexString(bytes).ToLower();

                var newRoot = new User
                {
                    Id = Guid.NewGuid().ToString(),
                    Username = "admin",
                    Email = rootAdminEmail,
                    FullName = "Super Admin tổng",
                    PasswordHash = passwordHash,
                    RoleId = 0, // Admin
                    IsApproved = true,
                    CanManageOrders = true,
                    CanManageFinance = true,
                    CanManageShops = true
                };
                context.Users.Add(newRoot);

                var wallet = new Wallet
                {
                    UserId = newRoot.Id,
                    Balance = 0,
                    UpdatedAt = DateTime.Now
                };
                context.Wallets.Add(wallet);
                context.SaveChanges();
                Console.WriteLine("Seeded default Super Admin: admin@langfood.vn / admin");
            }
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error seeding database: {ex.Message}");
    }
}

// 4. Cấu hình HTTP request pipeline (Middleware)
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios.
    app.UseHsts();
}

// Chú ý: Nếu Backend chạy http, Admin cũng nên chạy http để tránh lỗi SSL khi test local
// app.UseHttpsRedirection(); 

app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

// 5. Cấu hình Route mặc định: Khi chạy Web sẽ vào trang Home trước
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.MapHub<LangFoodAdmin.Hubs.OrderHub>("/orderHub");

// 6. Chạy ứng dụng
Console.WriteLine("LangFood Admin is starting...");
app.Run();