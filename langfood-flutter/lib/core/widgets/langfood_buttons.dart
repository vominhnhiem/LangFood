import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/app_motion.dart';

/// Nút bấm chính (Primary CTA) chuẩn phong cách iOS HIG của LangFood
/// - Bo góc 16px (squircle)
/// - Chiều cao 50px
/// - Hiệu ứng nhấn thu nhỏ (Press Scale 0.97) + Haptic Feedback
/// - Đầy đủ trạng thái: Normal, Loading, Disabled
class LangFoodPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;

  const LangFoodPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 50.0,
    this.borderRadius = AppTokens.radiusLg,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final bg = isEnabled
        ? (backgroundColor ?? AppColors.primary)
        : (context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300);
    final fg = isEnabled
        ? (textColor ?? Colors.white)
        : (context.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade500);

    return PressScaleWidget(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: AppMotion.durationFast,
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isEnabled ? AppTokens.shadowPrimaryButton : null,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd.copyWith(
                          color: fg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Nút bấm phụ (Secondary CTA) chuẩn phong cách iOS HIG của LangFood
/// Nền mờ nhận diện thương hiệu nhẹ nhàng (Tonal Surface), chữ cam đậm
class LangFoodSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const LangFoodSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 50.0,
    this.borderRadius = AppTokens.radiusLg,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final isDark = context.isDarkMode;

    final bg = isEnabled
        ? (isDark
              ? AppColors.primary.withOpacity(0.18)
              : AppColors.primary.withOpacity(0.12))
        : (isDark ? Colors.grey.shade900 : Colors.grey.shade200);

    final fg = isEnabled
        ? (isDark ? AppColors.primaryLight : AppColors.primary)
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    return PressScaleWidget(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: AppMotion.durationFast,
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: fg, strokeWidth: 2.2),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
