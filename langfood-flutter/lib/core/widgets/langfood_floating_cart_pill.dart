import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/app_motion.dart';

class LangFoodFloatingCartPill extends StatelessWidget {
  final int totalItemCount;
  final double totalPrice;
  final String label;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  const LangFoodFloatingCartPill({
    super.key,
    required this.totalItemCount,
    required this.totalPrice,
    this.label = 'Xem giỏ hàng',
    required this.onTap,
    this.margin = const EdgeInsets.symmetric(
      horizontal: AppTokens.marginMobile,
      vertical: AppTokens.spaceSm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    if (totalItemCount <= 0) return const SizedBox.shrink();

    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final formattedPrice = currencyFormatter
        .format(totalPrice)
        .replaceAll(' ', '');

    final textStyle = AppTypography.labelMd.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final count = _value(context, '$totalItemCount món', textStyle);
    final price = _value(
      context,
      formattedPrice,
      AppTypography.currencyDisplay.copyWith(color: Colors.white),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: PressScaleWidget(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: const BoxConstraints(minHeight: 54),
            decoration: const ShapeDecoration(
              color: AppColors.primaryDeep,
              shape: RoundedSuperellipseBorder(
                borderRadius: AppTokens.borderRadiusXl,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stack =
                    constraints.maxWidth < 250 ||
                    MediaQuery.textScalerOf(context).scale(14) > 19;
                final title = Text(
                  label,
                  style: textStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
                final details = Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppTokens.borderRadiusFull,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: count,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (!stack) Expanded(child: title) else const Spacer(),
                    const SizedBox(width: 8),
                    Flexible(child: price),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                );
                if (!stack) return details;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, const SizedBox(height: 4), details],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _value(BuildContext context, String value, TextStyle style) =>
      AnimatedSwitcher(
        duration: AppMotion.durationOf(context, AppMotion.durationNormal),
        child: Text(
          value,
          key: ValueKey(value),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
