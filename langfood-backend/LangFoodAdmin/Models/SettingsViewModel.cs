namespace LangFoodAdmin.Models
{
    public class SettingsViewModel
    {
        public bool IsMaintenanceMode { get; set; } = false;
        public string BroadcastMessage { get; set; } = "Chào mừng quý khách đến với Làng Food! Chúc quý khách ngon miệng!";
        public int MaxOrderPerShipper { get; set; } = 3;
    }
}
