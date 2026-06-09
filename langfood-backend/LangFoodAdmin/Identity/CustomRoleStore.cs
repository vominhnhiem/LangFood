using Microsoft.AspNetCore.Identity;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace LangFoodAdmin.Identity
{
    public class CustomRoleStore : IRoleStore<IdentityRole>
    {
        private readonly List<IdentityRole> _roles = new();

        public CustomRoleStore()
        {
            _roles.Add(new IdentityRole("Admin") { NormalizedName = "ADMIN" });
        }

        public Task<IdentityResult> CreateAsync(IdentityRole role, CancellationToken cancellationToken)
        {
            if (!_roles.Exists(r => r.Name == role.Name))
            {
                _roles.Add(role);
            }
            return Task.FromResult(IdentityResult.Success);
        }

        public Task<IdentityResult> DeleteAsync(IdentityRole role, CancellationToken cancellationToken)
        {
            _roles.RemoveAll(r => r.Name == role.Name);
            return Task.FromResult(IdentityResult.Success);
        }

        public void Dispose() { }

        public Task<IdentityRole?> FindByIdAsync(string roleId, CancellationToken cancellationToken)
        {
            var role = _roles.Find(r => r.Id == roleId);
            return Task.FromResult(role);
        }

        public Task<IdentityRole?> FindByNameAsync(string normalizedRoleName, CancellationToken cancellationToken)
        {
            var role = _roles.Find(r => r.NormalizedName == normalizedRoleName);
            return Task.FromResult(role);
        }

        public Task<string> GetRoleIdAsync(IdentityRole role, CancellationToken cancellationToken)
        {
            return Task.FromResult(role.Id);
        }

        public Task<string?> GetRoleNameAsync(IdentityRole role, CancellationToken cancellationToken)
        {
            return Task.FromResult<string?>(role.Name);
        }

        public Task SetRoleNameAsync(IdentityRole role, string? roleName, CancellationToken cancellationToken)
        {
            role.Name = roleName;
            return Task.CompletedTask;
        }

        public Task<string?> GetNormalizedRoleNameAsync(IdentityRole role, CancellationToken cancellationToken)
        {
            return Task.FromResult<string?>(role.NormalizedName);
        }

        public Task SetNormalizedRoleNameAsync(IdentityRole role, string? normalizedName, CancellationToken cancellationToken)
        {
            role.NormalizedName = normalizedName;
            return Task.CompletedTask;
        }

        public Task<IdentityResult> UpdateAsync(IdentityRole role, CancellationToken cancellationToken)
        {
            return Task.FromResult(IdentityResult.Success);
        }
    }
}
