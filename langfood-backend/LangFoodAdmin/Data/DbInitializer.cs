using Microsoft.AspNetCore.Identity;
using System;
using System.Threading.Tasks;
using LangFood.Shared.Models;

namespace LangFoodAdmin.Data
{
    public static class DbInitializer
    {
        public static async Task SeedAsync(LangFoodDbContext context, UserManager<User> userManager, RoleManager<IdentityRole> roleManager)
        {
            context.Database.EnsureCreated();

            // 1. Tạo Role Admin duy nhất nếu chưa tồn tại
            if (!await roleManager.RoleExistsAsync("Admin"))
            {
                await roleManager.CreateAsync(new IdentityRole("Admin"));
            }

            // 2. Tạo tài khoản admin@langfood.com duy nhất nếu chưa tồn tại
            var adminUser = await userManager.FindByEmailAsync("admin@langfood.com");
            if (adminUser == null)
            {
                adminUser = new User
                {
                    Id = Guid.NewGuid().ToString(),
                    Username = "admin",
                    Email = "admin@langfood.com",
                    FullName = "Làng Food Administrator",
                    RoleId = 1, // Admin
                    IsApproved = true
                };

                var createResult = await userManager.CreateAsync(adminUser, "Admin@123");
                if (createResult.Succeeded)
                {
                    await userManager.AddToRoleAsync(adminUser, "Admin");
                }
            }
        }
    }
}
