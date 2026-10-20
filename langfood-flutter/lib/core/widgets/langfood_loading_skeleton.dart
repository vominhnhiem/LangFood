import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Khung xương tải trang (Skeleton Shimmer) dùng cho các trạng thái Loading
/// Hoạt động mượt mà bằng AnimationController nguyên bản của Flutter
class LangFoodLoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const LangFoodLoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppTokens.radiusMd,
    this.shape = BoxShape.rectangle,
  });

  /// Factory tiện ích cho hình tròn (Avatar)
  factory LangFoodLoadingSkeleton.circle({required double size}) {
    return LangFoodLoadingSkeleton(
      width: size,
      height: size,
      shape: BoxShape.circle,
      borderRadius: size / 2,
    );
  }

  /// Factory tiện ích cho dòng chữ (Text line)
  factory LangFoodLoadingSkeleton.text({
    double width = double.infinity,
    double height = 14,
    double borderRadius = 4,
  }) {
    return LangFoodLoadingSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  /// Factory thẻ món ăn tải trước (Food Card Skeleton)
  static Widget cardSkeleton(BuildContext context) {
    final theme = context.langFoodTheme;
    return Container(
      width: 170,
      padding: const EdgeInsets.all(AppTokens.spaceSm),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LangFoodLoadingSkeleton(
            width: double.infinity,
            height: 120,
            borderRadius: AppTokens.radiusMd,
          ),
          const SizedBox(height: 10),
          LangFoodLoadingSkeleton.text(width: 120, height: 14),
          const SizedBox(height: 6),
          LangFoodLoadingSkeleton.text(width: 80, height: 12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LangFoodLoadingSkeleton.text(width: 60, height: 16),
              LangFoodLoadingSkeleton.circle(size: 28),
            ],
          ),
        ],
      ),
    );
  }

  @override
  State<LangFoodLoadingSkeleton> createState() =>
      _LangFoodLoadingSkeletonState();
}

class _LangFoodLoadingSkeletonState extends State<LangFoodLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.4,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              shape: widget.shape,
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}
