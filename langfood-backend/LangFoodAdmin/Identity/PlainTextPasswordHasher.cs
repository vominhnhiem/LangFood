using Microsoft.AspNetCore.Identity;
using LangFood.Shared.Models;

namespace LangFoodAdmin.Identity
{
    public class PlainTextPasswordHasher : IPasswordHasher<User>
    {
        public string HashPassword(User user, string password)
        {
            return password;
        }

        public PasswordVerificationResult VerifyHashedPassword(User user, string hashedPassword, string providedPassword)
        {
            return hashedPassword == providedPassword 
                ? PasswordVerificationResult.Success 
                : PasswordVerificationResult.Failed;
        }
    }
}
