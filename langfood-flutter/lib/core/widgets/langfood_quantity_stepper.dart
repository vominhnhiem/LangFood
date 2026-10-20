import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/app_motion.dart';

/// Bộ điều khiển tăng giảm số lượng (Quantity Stepper) chuẩn Stitch V1
/// - Kiểu dáng Capsule Pill liên tục (9999px)
/// - Số hiển thị Tabular Figures chống giật layout
/// - Khi số lượng = 1, nút giảm chuyển thành icon Thùng rác (Xóa món)
class LangFoodQuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback? onDelete;
  final int min;
  final int max;

  const LangFoodQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.onDelete,
    this.min = 1,
    this.max = 99,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    final bg = isDark ? theme.surfaceContainerLow : theme.surfaceContainerLow;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút Trừ / Thùng rác
          _buildActionButton(
            icon: value <= min
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            color: value <= min ? AppColors.errorApple : theme.textPrimary,
            onTap: () {
              if (value <= min) {
                onDelete?.call();
              } else {
                onChanged(value - 1);
              }
            },
          ),

          // Hiển thị số lượng
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$value',
              style: AppTypography.counterDisplay.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Nút Cộng
          _buildActionButton(
            icon: Icons.add_rounded,
            color: AppColors.primary,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return PressScaleWidget(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: onTap != null ? color : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
