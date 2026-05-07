using LangFood.Shared;
using LangFood.Shared.Models;
using Microsoft.EntityFrameworkCore;
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

var app = builder.Build();

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

app.UseAuthorization();

// 5. Cấu hình Route mặc định: Khi chạy Web sẽ vào trang Home trước
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

// 6. Chạy ứng dụng
Console.WriteLine("LangFood Admin is starting...");
app.Run();