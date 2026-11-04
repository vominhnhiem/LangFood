import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roomController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _mssvController = TextEditingController();

  int _selectedRoleId = 1; // 1: Sinh viên, 2: Chủ quán, 3: Shipper
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> _buildings = [];
  int? _selectedBuildingId;
  bool _isBuildingFromApi = false;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roomController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _mssvController.dispose();
    super.dispose();
  }

  void _setFallbackBuildings() {
    _buildings = [
      {'id': 1, 'name': 'Tòa A1'},
      {'id': 2, 'name': 'Tòa A2'},
      {'id': 3, 'name': 'Tòa B1'},
      {'id': 4, 'name': 'Tòa B2'},
      {'id': 5, 'name': 'Tòa C1'},
    ];
    _isBuildingFromApi = false;
    _selectedBuildingId = 1;
  }

  Future<void> _loadBuildings() async {
    try {
      final list = await _authService.getBuildings();
      if (!mounted) return;
      setState(() {
        if (list.isNotEmpty) {
          _buildings = list;
          _isBuildingFromApi = true;
          _selectedBuildingId =
              (_buildings.first['id'] ?? _buildings.first['Id']) as int?;
        } else {
          _setFallbackBuildings();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _setFallbackBuildings();
      });
    }
  }

  Future<void> _handleStartRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    try {
      final msg = await _authService.sendOtp(email);
      if (!mounted) return;
      setState(() => _isLoading = false);

      _showOtpDialog(email, msg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi OTP: $e (Mẹo test: nhập mã 123456)'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Still show dialog so user can enter dev code 123456
      _showOtpDialog(email, 'Mẹo kiểm thử: Bạn có thể nhập mã test 123456');
    }
  }

  void _showOtpDialog(String email, String hint) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Xác thực Email',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mã OTP 6 số đã được gửi đến: $email',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: '123456',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    letterSpacing: 4,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(ctx),
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      final otp = otpController.text.trim();
                      if (otp.isEmpty) return;

                      final scaffold = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      setDialogState(() => isVerifying = true);
                      try {
                        await _authService.verifyOtp(email, otp);

                        // Perform registration
                        await _authService.register(
                          username: _usernameController.text.trim(),
                          password: _passwordController.text.trim(),
                          fullName: _fullNameController.text.trim(),
                          email: email,
                          phone: _phoneController.text.trim(),
                          buildingId: _isBuildingFromApi
                              ? _selectedBuildingId
                              : null,
                          ktxRoom: _selectedRoleId == 1
                              ? _roomController.text.trim()
                              : null,
                          roleId: _selectedRoleId,
                          shopName: _selectedRoleId == 2
                              ? _shopNameController.text.trim()
                              : null,
                          shopAddress: _selectedRoleId == 2
                              ? _shopAddressController.text.trim()
                              : null,
                          mssv: _selectedRoleId == 3
                              ? _mssvController.text.trim()
                              : null,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx); // Close dialog
                        }

                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text(
                              _selectedRoleId == 1
                                  ? 'Đăng ký tài khoản thành công! Vui lòng đăng nhập.'
                                  : 'Đăng ký thành công! Hồ sơ của bạn đang chờ Quản trị viên duyệt trước khi có thể hoạt động.',
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );

                        navigator.pop(); // Return to LoginScreen
                      } catch (e) {
                        setDialogState(() => isVerifying = false);
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text('Lỗi: $e'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Xác nhận & Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Đăng ký tài khoản',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo tài khoản Làng Food',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đặt đồ ăn nhanh chóng, ship tận phòng KTX',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Role Selector
                _buildRoleSelector(),
                const SizedBox(height: 20),

                // Full Name
                _buildFieldTitle(
                  _selectedRoleId == 2
                      ? 'Họ và tên chủ quán *'
                      : (_selectedRoleId == 3
                            ? 'Họ và tên tài xế *'
                            : 'Họ và tên *'),
                ),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecoration(
                    'Ví dụ: Nguyễn Văn A',
                    Icons.badge_outlined,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập họ và tên'
                      : null,
                ),
                const SizedBox(height: 16),

                // Username
                _buildFieldTitle('Tên đăng nhập *'),
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration(
                    'Ví dụ: nguyenvana',
                    Icons.person_outline_rounded,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập tên đăng nhập';
                    }
                    if (v.trim().length < 3) return 'Tối thiểu 3 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                _buildFieldTitle('Email *'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    'Email (ví dụ: student@vnu.edu.vn)',
                    Icons.mail_outline_rounded,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                _buildFieldTitle('Số điện thoại *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    '09xxxxxxxx',
                    Icons.phone_outlined,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (v.trim().length != 10 || !v.trim().startsWith('0')) {
                      return 'SĐT phải có 10 chữ số bắt đầu bằng 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dynamic fields by selected role
                if (_selectedRoleId == 1) ...[
                  // KTX Building & Room
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldTitle('Tòa nhà KTX'),
                            _buildBuildingDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldTitle('Phòng'),
                            TextFormField(
                              controller: _roomController,
                              decoration: _inputDecoration(
                                'P. 402',
                                Icons.meeting_room_outlined,
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Nhập phòng'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (_selectedRoleId == 2) ...[
                  // Shop Name
                  _buildFieldTitle('Tên quán ăn *'),
                  TextFormField(
                    controller: _shopNameController,
                    decoration: _inputDecoration(
                      'Ví dụ: Cơm Tấm Đêm Tân Lập',
                      Icons.store_mall_directory_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập tên quán ăn'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Shop Address
                  _buildFieldTitle('Địa chỉ / Vị trí quán *'),
                  TextFormField(
                    controller: _shopAddressController,
                    decoration: _inputDecoration(
                      'Ví dụ: Tầng trệt C1 - KTX Khu B',
                      Icons.place_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập địa chỉ quán'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Nearest Building
                  _buildFieldTitle('Khu vực / Tòa KTX gần nhất'),
                  _buildBuildingDropdown(),
                  const SizedBox(height: 16),
                ] else if (_selectedRoleId == 3) ...[
                  // MSSV for Shipper
                  _buildFieldTitle('Mã số sinh viên (MSSV) *'),
                  TextFormField(
                    controller: _mssvController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Ví dụ: 21110123',
                      Icons.badge_outlined,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vui lòng nhập MSSV'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Building where shipper resides
                  _buildFieldTitle('Tòa nhà KTX đang lưu trú'),
                  _buildBuildingDropdown(),
                  const SizedBox(height: 16),
                ],

                // Password
                _buildFieldTitle('Mật khẩu *'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Tối thiểu 6 ký tự',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (v.trim().length < 4) {
                      return 'Mật khẩu tối thiểu 4 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                _buildFieldTitle('Xác nhận mật khẩu *'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleStartRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'TIẾP TỤC & XÁC THỰC OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Đã có tài khoản? Đăng nhập ngay',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle('Bạn đăng ký với vai trò *'),
        Row(
          children: [
            _buildRoleChip(1, Icons.school_outlined, 'Sinh viên', 'Đặt món'),
            const SizedBox(width: 8),
            _buildRoleChip(2, Icons.storefront_outlined, 'Chủ quán', 'Bán món'),
            const SizedBox(width: 8),
            _buildRoleChip(
              3,
              Icons.directions_bike_outlined,
              'Shipper',
              'Giao hàng',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleChip(
    int roleId,
    IconData icon,
    String label,
    String sublabel,
  ) {
    final isSelected = _selectedRoleId == roleId;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRoleId = roleId),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedBuildingId,
          items: _buildings.map((b) {
            final id = (b['id'] ?? b['Id']) as int;
            final name = (b['name'] ?? b['Name'] ?? 'Tòa $id').toString();
            return DropdownMenuItem<int>(
              value: id,
              child: Text(name, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedBuildingId = val);
            }
          },
        ),
      ),
    );
  }
}
