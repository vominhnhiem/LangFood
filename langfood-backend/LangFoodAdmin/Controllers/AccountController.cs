using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Identity;
using System.Threading.Tasks;
using LangFood.Shared.Models;
using LangFoodAdmin.Models;

namespace LangFoodAdmin.Controllers
{
    public class AccountController : Controller
    {
        private readonly UserManager<User> _userManager;
        private readonly SignInManager<User> _signInManager;

        public AccountController(UserManager<User> userManager, SignInManager<User> signInManager)
        {
            _userManager = userManager;
            _signInManager = signInManager;
        }

        [HttpGet]
        public IActionResult Login(string? returnUrl = null)
        {
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(LoginViewModel model, string? returnUrl = null)
        {
            if (ModelState.IsValid)
            {
                // Tìm kiếm user theo email của form đăng nhập
                var user = await _userManager.FindByEmailAsync(model.Email);
                if (user != null)
                {
                    // Đăng nhập bằng SignInManager sử dụng tên đăng nhập thực tế của user
                    var result = await _signInManager.PasswordSignInAsync(user.Username, model.Password, model.RememberMe, lockoutOnFailure: false);
                    if (result.Succeeded)
                    {
                        TempData["SuccessMessage"] = "Đăng nhập thành công!";
                        if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
                        {
                            return Redirect(returnUrl);
                        }
                        return RedirectToAction("Index", "Dashboard");
                    }
                }
                
                ModelState.AddModelError(string.Empty, "Tài khoản Email hoặc Mật khẩu không hợp lệ!");
            }
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            await _signInManager.SignOutAsync();
            return RedirectToAction(nameof(Login));
        }

        [HttpGet]
        public IActionResult AccessDenied()
        {
            return View();
        }
    }
}
