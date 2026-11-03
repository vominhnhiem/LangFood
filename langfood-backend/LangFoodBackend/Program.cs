using LangFood.Shared.Models;
using LangFoodBackend.Hubs;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình Controller
builder.Services.AddControllers(options =>
{
    options.SuppressImplicitRequiredAttributeForNonNullableReferenceTypes = true;
})
.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull;
});

builder.Services.AddEndpointsApiExplorer();

// Cấu hình Swagger kèm nút Authorize Bearer Token
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "LangFood API", 
        Version = "v1",
        Description = "Hệ thống Web API Làng Food có tích hợp bảo mật JWT Bearer Token theo chuẩn HUTECH."
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập Token theo cú pháp: Bearer {token của bạn}\nVí dụ: Bearer eyJhbGciOi...",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

builder.Services.AddDbContext<LangFoodDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddCors(options => options.AddDefaultPolicy(policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

// Cấu hình JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JWTKey");
var secretKey = jwtSettings["Secret"] ?? "LangFoodSuperSecretKeyForJWTSigning2026NguyenManhHung!@#";
var key = Encoding.UTF8.GetBytes(secretKey);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["ValidIssuer"] ?? "LangFoodBackend",
        ValidAudience = jwtSettings["ValidAudience"] ?? "LangFoodApp",
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ClockSkew = TimeSpan.Zero
    };
});

builder.Services.AddAuthorization();

int desiredPort = 5289;
int portToUse = desiredPort;
if (builder.Environment.IsDevelopment())
{
    portToUse = IsPortAvailable(desiredPort) ? desiredPort : 5289;
    builder.WebHost.ConfigureKestrel(options =>
    {
        options.ListenAnyIP(portToUse);
    });
}

builder.Services.AddMemoryCache();
builder.Services.AddScoped<LangFoodBackend.Services.EmailService>();
builder.Services.AddSignalR();

var app = builder.Build();

// 2. Kích hoạt Swagger
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "LangFood API v1");
    c.RoutePrefix = "swagger";
});

// 3. Middleware (Đúng thứ tự từ trên xuống dưới)
app.UseStaticFiles();
app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

// 4. Map Endpoints
app.MapGet("/", () => Results.Redirect("/swagger"));
app.MapControllers();
app.MapHub<LocationHub>("/locationHub");

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
