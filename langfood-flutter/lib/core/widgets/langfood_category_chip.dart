import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/app_motion.dart';

/// Chip phân loại danh mục dạng viên thuốc (Capsule Pill) chuẩn Stitch V1 / LF-01
/// - Chiều cao 36px
/// - Bo tròn hoàn toàn (9999px)
/// - Trạng thái Chọn: Nền cam `#FF5722`, chữ trắng, bóng mờ nhẹ
/// - Trạng thái Thường: Nền Card theo Theme, viền mỏng tinh tế
class LangFoodCategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? emoji;

  const LangFoodCategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;

    final bg = isSelected ? AppColors.primary : theme.card;
    final fg = isSelected ? Colors.white : theme.textPrimary;
    final border = isSelected
        ? Border.all(color: AppColors.primary, width: 1.0)
        : Border.all(color: theme.borderSubtle, width: 0.8);

    final shadow = isSelected ? AppTokens.shadowPrimaryButton : null;

    return PressScaleWidget(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.durationFast,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: border,
          boxShadow: shadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (emoji != null && emoji!.isNotEmpty) ...[
              Text(emoji!, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
