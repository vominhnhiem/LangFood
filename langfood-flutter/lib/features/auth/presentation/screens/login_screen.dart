import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/utils/app_motion.dart';
import '../widgets/auth_intro.dart';
import '../widgets/auth_landing.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _registering = false;
  bool _registerBusy = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillAccount(String username, String password) {
    _usernameController.text = username;
    _passwordController.text = password;
  }

  Future<void> _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoading || _formKey.currentState?.validate() != true) {
      return;
    }
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.user;
      final isPending =
          ((user?.isSeller == true || user?.roleId == 2) ||
              (user?.isShipper == true || user?.roleId == 3)) &&
          user?.isApproved != true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPending
                ? 'Xin chào ${user?.fullName ?? user?.username}! Hồ sơ đang chờ Quản trị viên duyệt.'
                : 'Xin chào, ${user?.fullName ?? user?.username}!',
          ),
          backgroundColor: isPending
              ? Colors.amber.shade800
              : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Đăng nhập không thành công',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _selectMode(bool register) {
    if (register == _registering || _registerBusy) return;
    FocusScope.of(context).unfocus();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() => _registering = register);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select<AuthProvider, bool>((auth) => auth.isLoading);
    final theme = Theme.of(context);
    final colors = context.langFoodTheme;
    return PopScope(
      canPop: !_registering,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _registering) _selectMode(false);
      },
      child: AuthIntro(
        child: AuthLanding(
          controller: _scrollController,
          tabs: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Đăng nhập')),
              ButtonSegment(value: true, label: Text('Đăng ký')),
            ],
            selected: {_registering},
            showSelectedIcon: false,
            onSelectionChanged: busy || _registerBusy
                ? null
                : (selection) => _selectMode(selection.single),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              animationDuration: AppMotion.durationOf(
                context,
                AppMotion.durationFast,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? theme.colorScheme.secondaryContainer
                    : colors.surfaceContainerLow,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? theme.colorScheme.onSecondaryContainer
                    : colors.textSecondary,
              ),
              side: WidgetStatePropertyAll(
                BorderSide(color: colors.borderSubtle),
              ),
            ),
          ),
          form: TweenAnimationBuilder<double>(
            key: ValueKey(_registering),
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.durationOf(context, AppMotion.durationNormal),
            curve: AppMotion.curveDefault,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, (1 - value) * 10),
              child: Opacity(opacity: value, child: child),
            ),
            child: _registering
                ? RegisterScreen(
                    onReturnToLogin: () => _selectMode(false),
                    onBusyChanged: (busy) =>
                        setState(() => _registerBusy = busy),
                  )
                : _loginForm(busy),
          ),
        ),
      ),
    );
  }

  Widget _loginForm(bool busy) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthFormHeading(
          kicker: 'HẸN Ở KHU B',
          title: 'Mừng bạn',
          accent: 'trở lại!',
          description: 'Đăng nhập để đặt món hoặc bắt đầu ca ở Khu B.',
        ),
        const SizedBox(height: 18),
        CustomTextField(
          controller: _usernameController,
          hintText: 'Tên đăng nhập / Email',
          prefixIcon: Icons.person_outline_rounded,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Vui lòng nhập tên đăng nhập'
              : null,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _passwordController,
          hintText: 'Mật khẩu',
          isPassword: true,
          prefixIcon: Icons.lock_outline_rounded,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Vui lòng nhập mật khẩu'
              : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: busy
                ? null
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vui lòng liên hệ quản trị viên KTX để khôi phục mật khẩu.',
                      ),
                    ),
                  ),
            child: const Text('Quên mật khẩu?'),
          ),
        ),
        FilledButton.icon(
          onPressed: busy ? null : _handleLogin,
          icon: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_forward_rounded),
          label: Text(busy ? 'Đang đăng nhập…' : 'ĐĂNG NHẬP'),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: const Text('Tài khoản kiểm thử'),
          leading: const Icon(Icons.science_outlined),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildQuickChip('Sinh viên (User)', 'nhiem', 'nhiem2512005'),
                _buildQuickChip('Chủ quán (Shop)', 'seller', '123456'),
                _buildQuickChip('Tài xế (Shipper)', 'shipper', '123456'),
              ],
            ),
          ],
        ),
      ],
    ),
  );
  Widget _buildQuickChip(String label, String u, String p) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: context.langFoodTheme.surfaceContainerLow,
      side: BorderSide(color: context.langFoodTheme.borderSubtle),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () => _fillAccount(u, p),
    );
  }
}
