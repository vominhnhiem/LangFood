import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_loading_skeleton.dart';
import '../../../../data/models/product_model.dart';

/// Thẻ món ăn trong thực đơn Quán ăn chuẩn thiết kế Stitch LF-02
/// - Bố cục ngang chuẩn: Thông tin món bên trái, Thumbnail vuông bên phải
/// - Nhãn thông tin (Signature, Giảm giá, Món hot)
/// - Giá tiền định dạng Tabular Figures kèm giá gốc gạch ngang
/// - Nút "Tùy chọn +" hoặc "Thêm +"
/// - Đảm bảo an toàn bố cục (Flexible / FittedBox / Ellipsis) chống tràn RenderFlex
class ShopProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final String? badgeText;
  final String? imageTag;

  const ShopProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.badgeText,
    this.imageTag,
  });

  String _formatVnd(double amount) {
    final int intAmount = amount.round();
    final String s = intAmount.toString();
    final StringBuffer sb = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      count++;
      sb.write(s[i]);
      if (count % 3 == 0 && i > 0) {
        sb.write('.');
      }
    }
    return '${sb.toString().split('').reversed.join()}₫';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final formattedPrice = _formatVnd(product.price);
    // Chỉ hiển thị giảm giá nếu badgeText có chứa ký hiệu % hoặc được chỉ định rõ
    final hasDiscount = badgeText != null && badgeText!.contains('%');
    final formattedOriginalPrice = hasDiscount
        ? _formatVnd(product.price * 1.25)
        : null;

    final hasOptions = product.optionGroups.isNotEmpty;
    final displayBadge = badgeText;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.marginMobile,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: theme.borderSubtle, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PressScaleWidget(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceSm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cột thông tin món ăn (bên trái)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge nhãn: e.g. Tên phân loại hoặc "% giảm giá" nếu có
                    if (displayBadge != null) ...[
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: hasDiscount
                                    ? AppColors.error.withValues(alpha: 0.12)
                                    : AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                displayBadge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasDiscount
                                      ? AppColors.error
                                      : AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Ưu đãi 🔥',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                    ],

                    // Tên món ăn
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMd.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Mô tả món ăn
                    if (product.description != null &&
                        product.description!.isNotEmpty)
                      Text(
                        product.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 11,
                          color: theme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Hàng giá tiền & nút hành động (Bảo vệ chống tràn RenderFlex)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    formattedPrice,
                                    style: AppTypography.currencyDisplay
                                        .copyWith(
                                          color: AppColors.primary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ),
                              if (formattedOriginalPrice != null) ...[
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    formattedOriginalPrice,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textSecondary.withValues(
                                        alpha: 0.7,
                                      ),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Nút thêm món / Tùy chọn (LF-02)
                        PressScaleWidget(
                          onTap: onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusFull,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hasOptions ? 'Tùy chọn' : 'Thêm',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.add_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 2. Thumbnail ảnh món ăn (bên phải)
              Stack(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: theme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: theme.borderSubtle, width: 0.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildProductImage(),
                  ),
                  if (imageTag != null)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          imageTag!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      final imgUrl = product.imageUrl!.startsWith('http')
          ? product.imageUrl!
          : '${AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/${product.imageUrl!.replaceAll(RegExp(r'^/'), '')}';

      return Image.network(
        imgUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const LangFoodLoadingSkeleton(width: 92, height: 92);
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }
}
