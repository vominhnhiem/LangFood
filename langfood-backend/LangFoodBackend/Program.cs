using LangFood.Shared.Models;
using LangFoodBackend.Hubs;
using Microsoft.EntityFrameworkCore;
using System.Net;
using System.Net.Sockets;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình Controller: Bỏ IgnoreCycles, dùng JsonIgnore ở Model cho nhanh
builder.Services.AddControllers(options =>
{
    options.SuppressImplicitRequiredAttributeForNonNullableReferenceTypes = true;
})
.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<LangFoodDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

int desiredPort = 5289;
int portToUse = IsPortAvailable(desiredPort) ? desiredPort : 5289;

builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(portToUse);
});

builder.Services.AddMemoryCache();
builder.Services.AddScoped<LangFoodBackend.Services.EmailService>();
// Thêm SignalR Service
builder.Services.AddSignalR();


var app = builder.Build();

// Luôn kích hoạt Swagger & Swagger UI để kiểm thử API thuận tiện
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "LangFood API v1");
    c.RoutePrefix = "swagger";
});

// Điều hướng trang gốc "/" thẳng vào giao diện Swagger Web API
app.MapGet("/", () => Results.Redirect("/swagger"));

// Mánh Hub (đặt trước app.Run())
app.MapHub<LocationHub>("/locationHub");

app.UseCors();
app.UseStaticFiles();
app.UseAuthorization();
app.MapControllers();

Console.WriteLine($"Server running on port {portToUse} -> http://localhost:{portToUse}/swagger");

await app.RunAsync();

// --- Helpers ---
static bool IsPortAvailable(int port)
{
    try
    {
        using var tcp = new Socket(AddressFamily.InterNetworkV6, SocketType.Stream, ProtocolType.Tcp);
        tcp.DualMode = true;
        tcp.Bind(new IPEndPoint(IPAddress.IPv6Any, port));
        return true;
    }
    catch
    {
        return false;
    }
}
