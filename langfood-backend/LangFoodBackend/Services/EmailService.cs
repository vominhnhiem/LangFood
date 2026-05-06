using MailKit.Net.Smtp;
using MimeKit;

namespace LangFoodBackend.Services
{
    public class EmailService
    {
        // Thay bằng email và mật khẩu ứng dụng của bạn
        private readonly string _fromEmail = "vominhnhiem20051@gmail.com";
        private readonly string _appPassword = "byby nzxz kjgw ljzp";

        public async Task SendOtpAsync(string toEmail, string otp)
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress("Làng Food", _fromEmail));
            message.To.Add(new MailboxAddress("", toEmail));
            message.Subject = "Mã xác thực đăng ký Làng Food";

            message.Body = new TextPart("plain")
            {
                Text = $"Mã OTP của bạn là: {otp}. Mã này có hiệu lực trong 5 phút. Vui lòng không cung cấp mã này cho bất kỳ ai!"
            };

            using (var client = new SmtpClient())
            {
                await client.ConnectAsync("smtp.gmail.com", 587, MailKit.Security.SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(_fromEmail, _appPassword);
                await client.SendAsync(message);
                await client.DisconnectAsync(true);
            }
        }
    }
}