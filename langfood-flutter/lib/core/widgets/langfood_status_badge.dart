import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
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
    Color bg;
    Color fg;

    switch (variant) {
      case StatusBadgeVariant.success:
        bg = AppColors.successApple.withOpacity(0.14);
        fg = AppColors.successApple;
        break;
      case StatusBadgeVariant.warning:
        bg = AppColors.accent.withOpacity(0.16);
        fg = const Color(0xFFE65100);
        break;
      case StatusBadgeVariant.info:
        bg = AppColors.info.withOpacity(0.14);
        fg = AppColors.info;
        break;
      case StatusBadgeVariant.error:
        bg = AppColors.errorApple.withOpacity(0.14);
        fg = AppColors.errorApple;
        break;
      case StatusBadgeVariant.primary:
        bg = AppColors.primary.withOpacity(0.14);
        fg = AppColors.primary;
        break;
      case StatusBadgeVariant.neutral:
        bg = Colors.grey.withOpacity(0.14);
        fg = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
