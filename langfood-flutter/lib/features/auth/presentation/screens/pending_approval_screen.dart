import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/langfood_buttons.dart';
import '../../../../core/widgets/langfood_card.dart';
import '../../../../core/widgets/langfood_status_badge.dart';
import '../../../../providers/auth_provider.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isRefreshing = false;

  Future<void> _checkApprovalStatus() async {
    setState(() => _isRefreshing = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final user = await authProvider.refreshProfile();
      if (!mounted) return;

      if (user != null && user.isApproved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chúc mừng! Tài khoản của bạn đã được Admin phê duyệt.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hồ sơ của bạn vẫn đang chờ Quản trị viên xét duyệt. Vui lòng thử lại sau!',
            ),
            backgroundColor: Colors.amber,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi làm mới trạng thái: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isSeller = user?.roleId == 2 || user?.isSeller == true;
    final colors = context.langFoodTheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Trạng thái tài khoản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            LangFoodCard(
              showShadow: false,
              showBorder: false,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LangFoodStatusBadge(
                    label: 'Đang chờ Admin duyệt',
                    variant: StatusBadgeVariant.warning,
                    icon: Icons.hourglass_top_rounded,
                  ),
                  const SizedBox(height: 12),
                  Text('Hồ sơ đang chờ phê duyệt', style: text.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    isSeller
                        ? 'Đối tác Chủ quán (Seller)'
                        : 'Đối tác Tài xế (Shipper)',
                    style: text.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LangFoodCard(
              showShadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Thông tin đăng ký', style: text.titleMedium),
                  const Divider(height: 24),
                  Text(
                    user?.fullName ?? user?.username ?? 'Chưa có họ tên',
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.username ?? 'Chưa có tên đăng nhập',
                    style: text.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (user?.phoneNumber case final String phone)
                    Text(
                      phone,
                      style: text.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Quản trị viên đang kiểm tra hồ sơ. Bạn có thể cập nhật trạng thái bên dưới.',
              style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            LangFoodPrimaryButton(
              text: 'KIỂM TRA TRẠNG THÁI',
              icon: Icons.refresh_rounded,
              isLoading: _isRefreshing,
              onPressed: _checkApprovalStatus,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _handleLogout,
              child: const Text('ĐĂNG XUẤT'),
            ),
          ],
        ),
      ),
    );
  }
}
