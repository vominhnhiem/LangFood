using System.Data;
using System.Security.Claims;
using System.Text.Json;
using LangFood.Shared.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LangFoodBackend.Controllers;

[ApiController]
[Authorize]
[Route("api/Lobby")]
public class LobbyController(LangFoodDbContext db) : ControllerBase
{
    private const int ShippingFee = 10000;
    private const int Capacity = 5;

    public sealed record OpenRoom(int ShopId, double Latitude, double Longitude);
    public sealed record Line(int ProductId, int Quantity, string? Note);
    public sealed record ConfirmPortion(Line[] Items);
    private sealed record PricedLine(int ProductId, int Quantity, decimal Price, string? Note);
    private sealed record Portion(string BuyerId, PricedLine[] Items);

    private Task<User?> Buyer()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return db.Users.FirstOrDefaultAsync(u => u.Id == id && u.RoleId == 1 && u.IsApproved);
    }

    private static List<Portion> Portions(LobbyRoom room) =>
        JsonSerializer.Deserialize<List<Portion>>(room.PortionsJson)!;

    [HttpGet]
    public async Task<IActionResult> List()
    {
        var buyer = await Buyer();
        if (buyer?.BuildingId is not int buildingId) return Forbid();

        var building = await db.Buildings.FindAsync(buildingId);
        if (building == null || !building.IsActive) return Forbid();

        var now = DateTime.UtcNow;
        var rooms = await db.LobbyRooms.AsNoTracking()
            .Where(r => r.BuildingId == buildingId &&
                ((r.OrderId == null && r.ClosesAt > now) ||
                    db.Orders.Any(o => o.Id == r.OrderId &&
                        (o.Status == "Pending" || o.Status == "Preparing" ||
                         o.Status == "Ready" || o.Status == "PickingUp" ||
                         o.Status == "Delivering" || o.Status == "Confirmed" ||
                         o.Status == "Accepted"))))
            .OrderByDescending(r => r.Id).ToListAsync();
        var shopIds = rooms.Select(r => r.ShopId).Distinct().ToArray();
        var names = await db.Shops.Where(s => shopIds.Contains(s.Id))
            .ToDictionaryAsync(s => s.Id, s => s.Name);
        return Ok(new
        {
            buildingId,
            buildingName = building.Name,
            rooms = rooms.Select(room =>
            {
                var portions = Portions(room);
                var mine = portions.Find(p => p.BuyerId == buyer.Id);
                var host = room.HostId == buyer.Id;
                var open = room.OrderId == null && room.ClosesAt > now;
                return new { room, portions, mine, host, open };
            }).Where(x => x.open || x.mine != null).Select(x => new
            {
                x.room.Id,
                x.room.ShopId,
                ShopName = names.GetValueOrDefault(x.room.ShopId, "Quán ăn"),
                x.room.Address,
                ClosesAt = DateTime.SpecifyKind(x.room.ClosesAt, DateTimeKind.Utc),
                Participants = x.portions.Count,
                x.open,
                Joined = x.mine != null,
                CanCancel = x.open && x.host,
                CanFinalize = x.open && x.host && x.mine != null,
                HostShippingQuote = x.open && x.host && x.mine != null
                    ? ShippingFee / x.portions.Count + ShippingFee % x.portions.Count : (int?)null,
                OrderId = x.mine != null ? x.room.OrderId : null,
                FoodTotal = x.mine?.Items.Sum(line => line.Price * line.Quantity),
                PortionNumber = x.room.OrderId != null && x.mine != null
                    ? x.portions.IndexOf(x.mine) + 1 : (int?)null,
                ShippingShare = x.room.OrderId != null && x.mine != null
                    ? ShippingFee / x.portions.Count + (x.host ? ShippingFee % x.portions.Count : 0) : (int?)null
            })
        });
    }

    [HttpPost]
    public async Task<IActionResult> Open(OpenRoom input)
    {
        var buyer = await Buyer();
        if (buyer?.BuildingId is not int buildingId) return Forbid();
        if (!double.IsFinite(input.Latitude) || !double.IsFinite(input.Longitude) ||
            Math.Abs(input.Latitude) > 90 || Math.Abs(input.Longitude) > 180)
            return BadRequest(new { message = "Điểm nhận tại sảnh không hợp lệ." });
        var building = await db.Buildings.FindAsync(buildingId);
        if (building == null || !building.IsActive) return Forbid();
        if (!await db.Shops.AnyAsync(s => s.Id == input.ShopId && s.IsActive && s.IsOpen))
            return BadRequest(new { message = "Quán hiện không nhận đơn." });

        var now = DateTime.UtcNow;
        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        if (await db.LobbyRooms.AnyAsync(r =>
            r.HostId == buyer.Id && r.OrderId == null && r.ClosesAt > now))
            return Conflict(new { message = "Bạn đã có một phòng đang mở." });
        var room = new LobbyRoom
        {
            HostId = buyer.Id, ShopId = input.ShopId, BuildingId = buildingId,
            Address = $"Sảnh {building.Name}", ClosesAt = now.AddMinutes(10),
            Latitude = input.Latitude, Longitude = input.Longitude
        };
        db.LobbyRooms.Add(room);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return Ok(new { room.Id });
    }

    [HttpPut("{id}/portion")]
    public async Task<IActionResult> Confirm(int id, ConfirmPortion input)
    {
        var buyer = await Buyer();
        if (buyer?.BuildingId is not int buildingId) return Forbid();
        if (input.Items == null || input.Items.Length is < 1 or > 20 ||
            input.Items.Any(i => i.Quantity is < 1 or > 20 || i.Note?.Length > 200))
            return BadRequest(new { message = "Số món, số lượng hoặc ghi chú không hợp lệ." });

        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var room = await db.LobbyRooms.FindAsync(id);
        if (room == null || room.BuildingId != buildingId) return NotFound();
        var portions = Portions(room);
        if (room.OrderId.HasValue && portions.Any(p => p.BuyerId == buyer.Id))
            return Ok(new { room.OrderId });
        if (room.OrderId.HasValue || room.ClosesAt <= DateTime.UtcNow)
            return Conflict(new { message = "Phòng đã đóng." });
        if (portions.All(p => p.BuyerId != buyer.Id) && portions.Count >= Capacity)
            return Conflict(new { message = "Phòng đã đủ người." });
        if (!await db.Shops.AnyAsync(s => s.Id == room.ShopId && s.IsActive && s.IsOpen))
            return Conflict(new { message = "Quán hiện không nhận đơn." });
        var ids = input.Items.Select(i => i.ProductId).Distinct().ToArray();
        var products = await db.Products.Where(p => ids.Contains(p.Id) &&
            p.ShopId == room.ShopId && p.Status == 1 && p.IsAvailable && p.Price > 0)
            .ToDictionaryAsync(p => p.Id, p => p.Price);
        if (products.Count != ids.Length)
            return Conflict(new { message = "Có món đã ngừng bán hoặc không thuộc quán." });

        portions.RemoveAll(p => p.BuyerId == buyer.Id);
        portions.Add(new Portion(buyer.Id, input.Items.Select(i =>
            new PricedLine(i.ProductId, i.Quantity, products[i.ProductId], i.Note)).ToArray()));
        room.PortionsJson = JsonSerializer.Serialize(portions);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return Ok(new { room.OrderId });
    }

    [HttpDelete("{id}/portion")]
    public async Task<IActionResult> Withdraw(int id)
    {
        var buyer = await Buyer();
        if (buyer?.BuildingId is not int buildingId) return Forbid();
        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var room = await db.LobbyRooms.FindAsync(id);
        if (room == null || room.BuildingId != buildingId) return NotFound();
        if (room.OrderId.HasValue || room.ClosesAt <= DateTime.UtcNow)
            return Conflict(new { message = "Phòng đã đóng." });

        var portions = Portions(room);
        if (portions.RemoveAll(p => p.BuyerId == buyer.Id) > 0)
        {
            room.PortionsJson = JsonSerializer.Serialize(portions);
            await db.SaveChangesAsync();
        }
        await transaction.CommitAsync();
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> CancelRoom(int id)
    {
        var buyer = await Buyer();
        if (buyer?.BuildingId is not int buildingId) return Forbid();

        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var room = await db.LobbyRooms.FindAsync(id);
        if (room == null || room.BuildingId != buildingId || room.HostId != buyer.Id)
            return NotFound();
        if (room.OrderId.HasValue)
            return Conflict(new { message = "Phòng đã chốt và tạo đơn." });

        var now = DateTime.UtcNow;
        if (room.ClosesAt > now)
        {
            room.ClosesAt = now;
            await db.SaveChangesAsync();
        }
        await transaction.CommitAsync();
        return NoContent();
    }

    [HttpPost("{id}/finalize")]
    public async Task<IActionResult> FinalizeRoom(int id, [FromQuery] int? expectedParticipants)
    {
        var buyer = await Buyer();
        if (buyer?.BuildingId is not int buildingId) return Forbid();

        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var room = await db.LobbyRooms.FindAsync(id);
        if (room == null || room.BuildingId != buildingId || room.HostId != buyer.Id) return NotFound();
        if (room.OrderId.HasValue) return Ok(new { room.OrderId });
        var portions = Portions(room);
        if (room.ClosesAt <= DateTime.UtcNow ||
            portions.All(p => p.BuyerId != buyer.Id))
            return Conflict(new { message = "Phòng phải còn mở và chủ phòng phải xác nhận phần món của mình." });
        if (expectedParticipants.HasValue && expectedParticipants.Value != portions.Count)
            return Conflict(new { message = "Số phần đã thay đổi. Hãy tải lại phòng và kiểm tra phí trước khi đặt." });
        if (string.IsNullOrWhiteSpace(buyer.PhoneNumber))
            return BadRequest(new { message = "Chủ phòng cần số điện thoại để nhận đơn." });
        if (!await db.Shops.AnyAsync(s => s.Id == room.ShopId && s.IsActive && s.IsOpen))
            return Conflict(new { message = "Quán hiện không nhận đơn." });

        var buyers = portions.Select(p => p.BuyerId).ToArray();
        if (await db.Users.CountAsync(u => buyers.Contains(u.Id) &&
            u.BuildingId == buildingId && u.RoleId == 1 && u.IsApproved) != buyers.Length)
            return Conflict(new { message = "Có thành viên không còn đủ điều kiện tham gia phòng." });

        var ids = portions.SelectMany(p => p.Items).Select(i => i.ProductId).Distinct().ToArray();
        var prices = await db.Products.Where(p => ids.Contains(p.Id) && p.ShopId == room.ShopId &&
            p.Status == 1 && p.IsAvailable).ToDictionaryAsync(p => p.Id, p => p.Price);
        if (portions.SelectMany(p => p.Items).Any(i =>
            !prices.TryGetValue(i.ProductId, out var price) || price != i.Price))
            return Conflict(new { message = "Giá hoặc tình trạng món đã đổi. Hãy xác nhận lại các phần bị ảnh hưởng." });

        var order = new Order
        {
            BuyerId = buyer.Id, BuyerName = buyer.FullName, ShopId = room.ShopId,
            BuildingId = room.BuildingId, DeliveryBuilding = room.Address,
            DeliveryLatitude = room.Latitude, DeliveryLongitude = room.Longitude,
            DeliveryPhone = buyer.PhoneNumber, DeliveryRoom = $"Gom sảnh #{room.Id} • Chủ phòng nhận và thanh toán COD",
            ShippingFee = ShippingFee, PaymentMethod = 0, Status = "Pending",
            TotalAmount = portions.Sum(p => p.Items.Sum(i => i.Price * i.Quantity)),
            OrderItems = portions.SelectMany((p, index) => p.Items.Select(i => new OrderItem
            {
                ProductId = i.ProductId, Quantity = i.Quantity, UnitPrice = i.Price,
                Note = $"Phần {index + 1}" + (string.IsNullOrWhiteSpace(i.Note) ? "" : $" • {i.Note}")
            })).ToList()
        };
        db.Orders.Add(order);
        await db.SaveChangesAsync();
        room.OrderId = order.Id;
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return Ok(new { room.OrderId });
    }
}
