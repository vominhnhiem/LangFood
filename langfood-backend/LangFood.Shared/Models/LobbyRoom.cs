namespace LangFood.Shared.Models;

public class LobbyRoom
{
    public int Id { get; set; }
    public int BuildingId { get; set; }
    public int ShopId { get; set; }
    public string HostId { get; set; } = "";
    public DateTime ClosesAt { get; set; }
    public string Address { get; set; } = "";
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string PortionsJson { get; set; } = "[]";
    public int? OrderId { get; set; }
}
