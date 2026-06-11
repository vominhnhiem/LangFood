using System;

namespace LangFoodAdmin.Helpers
{
    public static class StatusHelper
    {
        public static string ToFriendlyTimeAgo(DateTime dt)
        {
            var ts = DateTime.Now - dt;
            if (ts.TotalSeconds < 60)
                return "Vừa xong";
            if (ts.TotalMinutes < 60)
                return $"{(int)ts.TotalMinutes} phút trước";
            if (ts.TotalHours < 24)
                return $"{(int)ts.TotalHours} giờ trước";
            if (ts.TotalDays < 30)
                return $"{(int)ts.TotalDays} ngày trước";
            return dt.ToString("dd/MM/yyyy HH:mm");
        }
    }
}
