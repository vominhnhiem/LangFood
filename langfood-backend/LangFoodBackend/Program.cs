using LangFoodBackend.Models;
using Microsoft.EntityFrameworkCore;
using System.Net;
using System.Net.Sockets;
using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers(options =>
{
    options.SuppressImplicitRequiredAttributeForNonNullableReferenceTypes = true;
});
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<LangFoodDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

// Preferred: configure Kestrel and pick a free port if 5289 is already taken.
int desiredPort = 5289;
int portToUse = IsPortAvailable(desiredPort) ? desiredPort : GetAvailablePort();

builder.WebHost.ConfigureKestrel(options =>
{
    options.ListenAnyIP(portToUse);
});

builder.Services.AddMemoryCache(); // Để lưu mã OTP tạm thời trong bộ nhớ
builder.Services.AddScoped<LangFoodBackend.Services.EmailService>();
var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
app.UseCors();
app.UseAuthorization();
app.UseStaticFiles();
app.MapControllers();

Console.WriteLine($"Starting on port {portToUse}");

// Start the app so Kestrel binds before opening the browser.
// Use StartAsync + WaitForShutdownAsync so we can open the correct Swagger URL (with the actual port) when debugging.
await app.StartAsync();

if (app.Environment.IsDevelopment() && Debugger.IsAttached)
{
    var swaggerUrl = $"http://localhost:{portToUse}/swagger";
    try
    {
        Process.Start(new ProcessStartInfo { FileName = swaggerUrl, UseShellExecute = true });
    }
    catch
    {
        // ignore failures to launch browser
    }
}

await app.WaitForShutdownAsync();

static bool IsPortAvailable(int port)
{
    try
    {
        TcpListener l = new TcpListener(IPAddress.Any, port);
        l.Start();
        l.Stop();
        return true;
    }
    catch (SocketException)
    {
        return false;
    }
}

static int GetAvailablePort()
{
    TcpListener l = new TcpListener(IPAddress.Loopback, 0);
    l.Start();
    int port = ((IPEndPoint)l.LocalEndpoint).Port;
    l.Stop();
    return port;
}
