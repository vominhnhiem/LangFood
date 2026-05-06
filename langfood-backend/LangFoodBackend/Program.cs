using LangFoodBackend.Models;
using Microsoft.EntityFrameworkCore;
using System.Net;
using System.Net.Sockets;

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
app.Run();

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
