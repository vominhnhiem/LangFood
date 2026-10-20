import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import 'langfood_buttons.dart';

/// Màn hình trạng thái trống (Empty State) chuẩn iOS HIG
/// Phục vụ cho giỏ hàng trống, không tìm thấy món, lịch sử đơn trống, v.v.
class LangFoodEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Widget? customIllustration;

  const LangFoodEmptyState({
    super.key,
    this.icon = Icons.fastfood_outlined,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.marginMobile * 1.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            customIllustration ??
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, size: 44, color: AppColors.primary),
                  ),
                ),
            const SizedBox(height: AppTokens.spaceLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMd.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: theme.textSecondary),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppTokens.spaceLg),
              SizedBox(
                width: 220,
                child: LangFoodPrimaryButton(
                  text: buttonText!,
                  onPressed: onButtonPressed,
                  height: 48,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
