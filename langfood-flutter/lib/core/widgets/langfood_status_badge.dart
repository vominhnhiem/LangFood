import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

enum StatusBadgeVariant { success, warning, info, error, primary, neutral }

/// Huy hiệu trạng thái (Status Badge) chuẩn Apple HIG / Stitch V1
/// Thể hiện trạng thái đơn hàng (Đang giao, Chuẩn bị, Hoàn thành...) hoặc Tag khuyến mãi
class LangFoodStatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;

  const LangFoodStatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final (accent, fg) = switch (variant) {
      StatusBadgeVariant.success => (
        AppColors.successApple,
        dark ? const Color(0xFF9BEAB3) : AppColors.tertiary,
      ),
      StatusBadgeVariant.warning => (
        AppColors.accent,
        dark ? const Color(0xFFFFCF82) : AppColors.secondary,
      ),
      StatusBadgeVariant.info => (
        AppColors.info,
        dark ? const Color(0xFFB2D8FF) : const Color(0xFF1A4D84),
      ),
      StatusBadgeVariant.error => (
        AppColors.error,
        dark ? const Color(0xFFFFB0A7) : AppColors.errorApple,
      ),
      StatusBadgeVariant.primary => (
        AppColors.primary,
        Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      StatusBadgeVariant.neutral => (
        context.langFoodTheme.textSecondary,
        context.langFoodTheme.textSecondary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: dark ? 0.20 : 0.13),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
