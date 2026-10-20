import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../utils/app_motion.dart';

/// Thẻ Card chuẩn phong cách Apple HIG (Level 1 Elevation)
/// - Bo góc 16px
/// - Viền mỏng 0.5px subtle
/// - Tự động thích ứng màu sắc giữa Light Mode và Dark Mode
/// - Hỗ trợ hiệu ứng chạm thu nhỏ (Press Scale 0.98) khi có onTap
class LangFoodCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final bool showBorder;
  final bool showShadow;

  const LangFoodCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.spaceMd),
    this.onTap,
    this.borderRadius = AppTokens.radiusLg,
    this.backgroundColor,
    this.showBorder = true,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    final bg = backgroundColor ?? theme.card;
    final border = showBorder
        ? Border.all(color: theme.borderSubtle, width: 0.5)
        : null;

    final shadows = showShadow
        ? (isDark ? AppTokens.shadowLevel1Dark : AppTokens.shadowLevel1)
        : null;

    final cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      return PressScaleWidget(onTap: onTap, child: cardContent);
    }

    return cardContent;
  }
}
