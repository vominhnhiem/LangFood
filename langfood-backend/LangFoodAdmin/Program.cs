using LangFood.Shared;
using LangFood.Shared.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;

var builder = WebApplication.CreateBuilder(args);

// 1. Thêm dịch vụ cho giao diện MVC (Controllers và Views)
builder.Services.AddControllersWithViews();

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

// 4. Cấu hình ASP.NET Core Identity tương thích với hệ thống hiện tại
builder.Services.AddIdentity<User, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequiredLength = 4;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequireUppercase = false;
    options.Password.RequireLowercase = false;
})
.AddUserStore<LangFoodAdmin.Identity.CustomUserStore>()
.AddRoleStore<LangFoodAdmin.Identity.CustomRoleStore>()
.AddDefaultTokenProviders();

// Sử dụng bộ mã hóa mật khẩu dạng PlainText để tương thích với toàn bộ Backend và Mobile
builder.Services.AddTransient<IPasswordHasher<User>, LangFoodAdmin.Identity.PlainTextPasswordHasher>();

builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Account/Login";
    options.AccessDeniedPath = "/Account/AccessDenied";
});

var app = builder.Build();

// 5. Cấu hình HTTP request pipeline (Middleware)
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

app.UseAuthentication(); // Đăng nhập trước
app.UseAuthorization();  // Phân quyền sau

// 6. Cấu hình Route mặc định: Khi chạy Web sẽ vào trang Dashboard trước
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Dashboard}/{action=Index}/{id?}");

// 7. Thực hiện Data Seeding tự động tài khoản Admin
using (var scope = app.Services.CreateScope())
{
    try
    {
        var services = scope.ServiceProvider;
        var context = services.GetRequiredService<LangFoodDbContext>();
        var userManager = services.GetRequiredService<UserManager<User>>();
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        await LangFoodAdmin.Data.DbInitializer.SeedAsync(context, userManager, roleManager);
    }
    catch (Exception ex)
    {
        Console.WriteLine("Lỗi khởi tạo dữ liệu Seed: " + ex.Message);
    }
}

// 8. Chạy ứng dụng
Console.WriteLine("LangFood Admin is starting...");
app.Run();