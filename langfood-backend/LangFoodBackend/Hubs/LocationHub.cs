using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace LangFoodBackend.Hubs
{
    public class LocationHub : Hub
    {
        public async Task UpdateLocation(string senderId, double latitude, double longitude)
        {
            await Clients.All.SendAsync("ReceiveLocation", senderId, latitude, longitude);
        }
    }
}