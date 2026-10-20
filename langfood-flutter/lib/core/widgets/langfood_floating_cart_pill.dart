import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/app_motion.dart';

/// Viên thuốc giỏ hàng nổi (Floating Cart Pill) chuẩn thiết kế Stitch LF-01 / Level 3 Elevation
/// - Nổi cố định phía trên thanh điều hướng hoặc cạnh đáy màn hình
/// - Tự động tính toán SafeArea
/// - Hiệu ứng kính mờ (BackdropFilter blur 20px)
/// - Số lượng và tổng tiền định dạng Tabular Figures chống giật
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: margin,
        child: PressScaleWidget(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  boxShadow: AppTokens.shadowLevel3,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Item Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusFull,
                        ),
                      ),
                      child: Text(
                        '$totalItemCount món',
                        style: AppTypography.labelMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Label / Action text
                    Expanded(
                      child: Text(
                        label,
                        style: AppTypography.titleMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Price display (Tabular figures)
                    Text(
                      formattedPrice,
                      style: AppTypography.currencyDisplay.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
