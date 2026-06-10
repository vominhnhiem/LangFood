using System;

namespace LangFood.Shared.Models
{
    public enum LogType
    {
        Order,
        Shipper,
        Shop,
        Danger,
        System
    }

    public class SystemLog
    {
        public int Id { get; set; }
        public string Content { get; set; } = string.Empty;
        public LogType LogType { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}
