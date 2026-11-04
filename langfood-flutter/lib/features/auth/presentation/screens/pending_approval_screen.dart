import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final isSeller = user?.roleId == 2 || user?.isSeller == true;
    final roleTitle = isSeller
        ? 'Đối tác Chủ quán (Seller)'
        : 'Đối tác Tài xế (Shipper)';
    final roleIcon = isSeller
        ? Icons.storefront_rounded
        : Icons.two_wheeler_rounded;

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Trạng thái tài khoản',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Hourglass Icon with Pulsing Accent
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 52,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Hồ sơ đang chờ phê duyệt',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Role chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Text(
                      roleTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Explanation text
              Text(
                isSeller
                    ? 'Yêu cầu mở quán của bạn đã được gửi thành công đến Quản trị viên LangFood. Chúng tôi đang kiểm tra thông tin và sẽ kích hoạt cửa hàng cho bạn trong thời gian sớm nhất.'
                    : 'Hồ sơ đăng ký tài xế shipper của bạn đã được tiếp nhận. Ban Quản trị LangFood đang đối soát thông tin sinh viên và KTX để phê duyệt cấp quyền giao hàng.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // Account Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Thông tin đăng ký',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 0.8),
                    _buildInfoRow(
                      'Họ và tên:',
                      user?.fullName ?? user?.username ?? '---',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Tên đăng nhập:', user?.username ?? '---'),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      'Số điện thoại:',
                      user?.phoneNumber ?? 'Chưa cập nhật',
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      'Trạng thái xét duyệt:',
                      'Đang chờ Admin duyệt',
                      valueColor: Colors.amber.shade800,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Help / notice box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quản trị viên thường duyệt yêu cầu trên Web Admin trong giờ làm việc. Bạn có thể bấm nút kiểm tra bên dưới để cập nhật tức thời khi hồ sơ được duyệt.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Primary Action: Refresh / Check status
              CustomButton(
                text: 'KIỂM TRA TRẠNG THÁI',
                icon: Icons.refresh_rounded,
                isLoading: _isRefreshing,
                onPressed: _checkApprovalStatus,
                backgroundColor: AppColors.primary,
              ),
              const SizedBox(height: 12),

              // Secondary Action: Logout
              CustomButton(
                text: 'ĐĂNG XUẤT',
                isOutlined: true,
                onPressed: _handleLogout,
                backgroundColor: AppColors.textSecondary,
                textColor: AppColors.textPrimary,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
