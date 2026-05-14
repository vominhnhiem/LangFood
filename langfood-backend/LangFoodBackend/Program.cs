using LangFood.Shared.Models;
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
int portToUse = IsPortAvailable(desiredPort) ? desiredPort : GetAvailablePort();

builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(portToUse);
});

builder.Services.AddMemoryCache();
builder.Services.AddScoped<LangFoodBackend.Services.EmailService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors();
app.UseStaticFiles();
app.UseAuthorization();
app.MapControllers();

Console.WriteLine($"Server running on port {portToUse}");

await app.RunAsync();

// --- Helpers ---
static bool IsPortAvailable(int port)
{
    try { TcpListener l = new TcpListener(IPAddress.Any, port); l.Start(); l.Stop(); return true; }
    catch { return false; }
}

static int GetAvailablePort()
{
    TcpListener l = new TcpListener(IPAddress.Loopback, 0); l.Start();
    int port = ((IPEndPoint)l.LocalEndpoint).Port; l.Stop(); return port;
}