using Microsoft.AspNetCore.Identity;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using LangFood.Shared.Models;
using Microsoft.EntityFrameworkCore;

namespace LangFoodAdmin.Identity
{
    public class CustomUserStore : IUserStore<User>, IUserPasswordStore<User>, IUserEmailStore<User>, IUserRoleStore<User>
    {
        private readonly LangFoodDbContext _context;

        public CustomUserStore(LangFoodDbContext context)
        {
            _context = context;
        }

        public async Task<IdentityResult> CreateAsync(User user, CancellationToken cancellationToken)
        {
            _context.Users.Add(user);
            await _context.SaveChangesAsync(cancellationToken);
            return IdentityResult.Success;
        }

        public async Task<IdentityResult> DeleteAsync(User user, CancellationToken cancellationToken)
        {
            _context.Users.Remove(user);
            await _context.SaveChangesAsync(cancellationToken);
            return IdentityResult.Success;
        }

        public void Dispose() { }

        public async Task<User?> FindByIdAsync(string userId, CancellationToken cancellationToken)
        {
            return await _context.Users.FindAsync(new object[] { userId }, cancellationToken);
        }

        public async Task<User?> FindByNameAsync(string normalizedUserName, CancellationToken cancellationToken)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Username.ToUpper() == normalizedUserName, cancellationToken);
        }

        public Task<string> GetNormalizedUserNameAsync(User user, CancellationToken cancellationToken)
        {
            return Task.FromResult(user.Username.ToUpper());
        }

        public Task<string> GetUserIdAsync(User user, CancellationToken cancellationToken)
        {
            return Task.FromResult(user.Id);
        }

        public Task<string?> GetUserNameAsync(User user, CancellationToken cancellationToken)
        {
            return Task.FromResult<string?>(user.Username);
        }

        public Task SetNormalizedUserNameAsync(User user, string? normalizedName, CancellationToken cancellationToken)
        {
            return Task.CompletedTask;
        }

        public Task SetUserNameAsync(User user, string? userName, CancellationToken cancellationToken)
        {
            user.Username = userName ?? "";
            return Task.CompletedTask;
        }

        public async Task<IdentityResult> UpdateAsync(User user, CancellationToken cancellationToken)
        {
            _context.Users.Update(user);
            await _context.SaveChangesAsync(cancellationToken);
            return IdentityResult.Success;
        }

        // Password Store
        public Task SetPasswordHashAsync(User user, string? passwordHash, CancellationToken cancellationToken)
        {
            user.PasswordHash = passwordHash ?? "";
            return Task.CompletedTask;
        }

        public Task<string?> GetPasswordHashAsync(User user, CancellationToken cancellationToken)
        {
            return Task.FromResult<string?>(user.PasswordHash);
        }

        public Task<bool> HasPasswordAsync(User user, CancellationToken cancellationToken)
        {
            return Task.FromResult(!string.IsNullOrEmpty(user.PasswordHash));
        }

        // Email Store
        public Task SetEmailAsync(User user, string? email, CancellationToken cancellationToken)
        {
            user.Email = email;
            return Task.CompletedTask;
        }

        public Task<string?> GetEmailAsync(User user, CancellationToken cancellationToken)
        {
            return Task.FromResult(user.Email);
        }

        public Task<bool> GetEmailConfirmedAsync(User user, CancellationToken cancellationToken)
        {
            return Task.FromResult(true);
        }

        public Task SetEmailConfirmedAsync(User user, bool confirmed, CancellationToken cancellationToken)
        {
            return Task.CompletedTask;
        }

        public async Task<User?> FindByEmailAsync(string normalizedEmail, CancellationToken cancellationToken)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Email != null && u.Email.ToUpper() == normalizedEmail, cancellationToken);
        }

        public Task<string?> GetNormalizedEmailAsync(User user, CancellationToken cancellationToken)
        {
            return Task.FromResult(user.Email?.ToUpper());
        }

        public Task SetNormalizedEmailAsync(User user, string? normalizedEmail, CancellationToken cancellationToken)
        {
            return Task.CompletedTask;
        }

        // Role Store
        public Task AddToRoleAsync(User user, string roleName, CancellationToken cancellationToken)
        {
            if (roleName.Equals("Admin", System.StringComparison.OrdinalIgnoreCase))
            {
                user.RoleId = 1; // 1 represents Admin
            }
            return Task.CompletedTask;
        }

        public Task RemoveFromRoleAsync(User user, string roleName, CancellationToken cancellationToken)
        {
            return Task.CompletedTask;
        }

        public Task<IList<string>> GetRolesAsync(User user, CancellationToken cancellationToken)
        {
            IList<string> roles = new List<string>();
            if (user.RoleId == 1)
            {
                roles.Add("Admin");
            }
            return Task.FromResult(roles);
        }

        public Task<bool> IsInRoleAsync(User user, string roleName, CancellationToken cancellationToken)
        {
            if (roleName.Equals("Admin", System.StringComparison.OrdinalIgnoreCase))
            {
                return Task.FromResult(user.RoleId == 1);
            }
            return Task.FromResult(false);
        }

        public Task<IList<User>> GetUsersInRoleAsync(string roleName, CancellationToken cancellationToken)
        {
            return Task.FromResult<IList<User>>(new List<User>());
        }
    }
}
