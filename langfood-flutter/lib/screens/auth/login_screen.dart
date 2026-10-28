import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/shipper/presentation/screens/shipper_orders_screen.dart';
import '../../features/restaurant/presentation/screens/shop_orders_screen.dart';
import 'register_screen.dart';

enum LoginViewState {
  normal,
  loading,
  error,
  biometric,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'sinhvien');
  final _passwordController = TextEditingController(text: '1232123@');

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isDarkMode = false;
  LoginViewState _viewState = LoginViewState.normal;

  late AnimationController _fadeAnimController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fadeAnimController.dispose();
    super.dispose();
  }

  void _triggerHaptic([HapticFeedbackType type = HapticFeedbackType.lightImpact]) {
    try {
      if (type == HapticFeedbackType.selectionClick) {
        HapticFeedback.selectionClick();
      } else if (type == HapticFeedbackType.mediumImpact) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void _fillAccount(String username, String password) {
    _triggerHaptic(HapticFeedbackType.selectionClick);
    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _triggerHaptic(HapticFeedbackType.mediumImpact);
      return;
    }

    _triggerHaptic(HapticFeedbackType.mediumImpact);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.user;
      final isShipper = user?.roleId == 3 || user?.shipperId != null || user?.username.toLowerCase() == 'shipper';
      final isShop = user?.roleId == 2 || user?.shopId != null || user?.username.toLowerCase() == 'quanan';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Chào mừng ${user?.fullName ?? user?.username} quay lại Làng Food!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Widget destination;
      if (isShipper) {
        destination = const ShipperOrdersScreen();
      } else if (isShop) {
        destination = const ShopOrdersScreen();
      } else {
        destination = const HomeScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      setState(() => _viewState = LoginViewState.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Tên đăng nhập hoặc mật khẩu không chính xác'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _simulateBiometricLogin() {
    _triggerHaptic(HapticFeedbackType.mediumImpact);
    setState(() => _viewState = LoginViewState.biometric);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.fingerprint_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Xác thực Face ID / Vân tay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quét sinh trắc học sinh viên KTX Làng Đại Học để đăng nhập siêu tốc...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _viewState = LoginViewState.normal);
                  _fillAccount('nhiem', 'nhiem2512005');
                  _handleLogin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Xác thực thành công (Khớp)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        final emailCtrl = TextEditingController(text: 'sinhvien@hcmut.edu.vn');
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2.5)),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 10),
                  Text('Khôi phục mật khẩu KTX', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập Email sinh viên (@hcmut, @uit, @ussh, @hcmus) để nhận mã OTP đặt lại mật khẩu:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  hintText: 'Email sinh viên',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã gửi mã OTP 6 số đến email của bạn! Vui lòng kiểm tra hộp thư.'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('GỬI MÃ XÁC THỰC OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _skipToGuestMode() {
    _triggerHaptic(HapticFeedbackType.lightImpact);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeBg = _isDarkMode ? const Color(0xFF121214) : const Color(0xFFF8F9FA);
    final themeCard = _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final themeTextPrimary = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final themeTextSecondary = _isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF64748B);
    final themeBorder = _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: themeBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Developer Inspector Bar
            _buildInspectorBar(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),

            // 2. Scrollable Auth Body
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // App Hero Brand Icon (Apple HIG Continuous Squircle 28pt)
                        _buildHeroBrandIcon(),
                        const SizedBox(height: 18),

                        // Large Title & Subtitle
                        Text(
                          'Đăng nhập LangFood',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: themeTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Campus Express 🍜 • Đồ ăn nóng hổi tận phòng KTX Khu A & B',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: themeTextSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Form Container Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: themeCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: themeBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username Field
                              Text(
                                'TÊN ĐĂNG NHẬP / EMAIL KTX',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: themeTextSecondary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _usernameController,
                                style: TextStyle(fontSize: 14, color: themeTextPrimary, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: 'Nhập username (vd: nhiem)',
                                  hintStyle: TextStyle(fontSize: 13, color: themeTextSecondary),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                                  suffixIcon: _usernameController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18),
                                          onPressed: () => setState(() => _usernameController.clear()),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                                  ),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
                              ),
                              const SizedBox(height: 18),

                              // Password Field
                              Text(
                                'MẬT KHẨU',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: themeTextSecondary,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(fontSize: 14, color: themeTextPrimary, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  hintText: 'Nhập mật khẩu',
                                  hintStyle: TextStyle(fontSize: 13, color: themeTextSecondary),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: themeTextSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                                  ),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                              ),
                              const SizedBox(height: 14),

                              // Remember Me & Forgot Password Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ghi nhớ đăng nhập',
                                        style: TextStyle(fontSize: 12.5, color: themeTextSecondary, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: _showForgotPasswordSheet,
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    child: const Text(
                                      'Quên mật khẩu?',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Quick Test Login Chips
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: themeBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CHỌN NHANH VAI TRÒ ĐỂ TEST (PASS: 1232123@):',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: themeTextSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              _usernameController.text = 'sinhvien';
                                              _passwordController.text = '1232123@';
                                              _handleLogin();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                              ),
                                              child: const Column(
                                                children: [
                                                  Icon(Icons.school_rounded, color: Colors.blue, size: 18),
                                                  SizedBox(height: 2),
                                                  Text('Sinh viên', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              _usernameController.text = 'quanan';
                                              _passwordController.text = '1232123@';
                                              _handleLogin();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                              ),
                                              child: const Column(
                                                children: [
                                                  Icon(Icons.restaurant_rounded, color: Colors.orange, size: 18),
                                                  SizedBox(height: 2),
                                                  Text('Quán ăn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              _usernameController.text = 'shipper';
                                              _passwordController.text = '1232123@';
                                              _handleLogin();
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                                              ),
                                              child: const Column(
                                                children: [
                                                  Icon(Icons.delivery_dining_rounded, color: Colors.green, size: 18),
                                                  SizedBox(height: 2),
                                                  Text('Shipper', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Login CTA Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppColors.primary.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login_rounded, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'ĐĂNG NHẬP VÀO LÀNG FOOD',
                                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Biometric Button
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: _simulateBiometricLogin,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: themeTextPrimary,
                                    side: BorderSide(color: themeBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Đăng nhập bằng Face ID / Vân tay KTX',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: themeTextPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Quick Role Fill (Demo Accounts)
                        _buildQuickRoleSwitcher(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
                        const SizedBox(height: 20),

                        // Guest Mode Button
                        TextButton(
                          onPressed: _skipToGuestMode,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Khám phá món ngon trước mà không cần đăng nhập',
                                style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Chưa có tài khoản sinh viên? ',
                              style: TextStyle(fontSize: 13, color: themeTextSecondary),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text(
                                'Đăng ký ngay',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TOP INSPECTOR CONTROLS =================
  Widget _buildInspectorBar(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFFE2E8F0),
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              'LF-Auth:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(width: 8),

            // Light / Dark Mode Toggle
            InkWell(
              onTap: () {
                _triggerHaptic(HapticFeedbackType.selectionClick);
                setState(() => _isDarkMode = !_isDarkMode);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.amber.withOpacity(0.2) : Colors.indigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      size: 13,
                      color: _isDarkMode ? Colors.amber : Colors.indigo,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isDarkMode ? 'Light' : 'Dark',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.amber : Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // State: Normal
            _buildStateChip(LoginViewState.normal, 'Chuẩn (Form)', Icons.edit_note_rounded, const Color(0xFF10B981)),
            const SizedBox(width: 6),

            // State: Biometric
            _buildStateChip(LoginViewState.biometric, 'FaceID / TouchID', Icons.fingerprint_rounded, const Color(0xFF6366F1)),
            const SizedBox(width: 6),

            // State: Error
            _buildStateChip(LoginViewState.error, 'Báo lỗi nhập', Icons.error_outline_rounded, const Color(0xFFEF4444)),
            const SizedBox(width: 10),

            // Direct shortcut to Home (LF-01)
            InkWell(
              onTap: _skipToGuestMode,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF8A65)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Vào LF-01 Home', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateChip(LoginViewState state, String label, IconData icon, Color color) {
    final isSelected = _viewState == state;
    return InkWell(
      onTap: () {
        _triggerHaptic(HapticFeedbackType.selectionClick);
        setState(() => _viewState = state);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HERO BRAND ICON =================
  Widget _buildHeroBrandIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 46,
          color: Colors.white,
        ),
      ),
    );
  }

  // ================= QUICK ROLE SWITCHER =================
  Widget _buildQuickRoleSwitcher(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 16, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                'Điền nhanh tài khoản kiểm thử (Demo Roles):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRoleChip(
                label: '🎓 Sinh viên',
                sub: 'nhiem',
                color: const Color(0xFF10B981),
                onTap: () => _fillAccount('nhiem', 'nhiem2512005'),
              ),
              _buildRoleChip(
                label: '🏪 Chủ quán',
                sub: 'seller',
                color: const Color(0xFFF59E0B),
                onTap: () => _fillAccount('seller', '123456'),
              ),
              _buildRoleChip(
                label: '🛵 Tài xế KTX',
                sub: 'shipper',
                color: const Color(0xFF6366F1),
                onTap: () => _fillAccount('shipper', '123456'),
              ),
              _buildRoleChip(
                label: '🛡️ Quản trị viên',
                sub: 'admin',
                color: const Color(0xFFEC4899),
                onTap: () => _fillAccount('admin', 'Admin@123'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip({
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 4),
            Text(
              '($sub)',
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  selectionClick,
}
