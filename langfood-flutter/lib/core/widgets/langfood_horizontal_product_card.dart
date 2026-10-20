import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/product_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../utils/app_motion.dart';
import 'langfood_card.dart';

/// Thẻ món ăn / quán ăn dạng ngang chuẩn thiết kế Stitch LF-01 (Quán ngon sinh viên chấm cao 🌟)
/// - Ảnh món 92x92 bo góc 16px kèm badge điểm đánh giá ⭐ 4.9
/// - Huy hiệu tag khuyến mãi (Freeship KTX, Combo sinh viên, Tặng trà tắc)
/// - Thời gian giao dự kiến (• 15 phút)
/// - Tiêu đề món ăn, địa chỉ / tên quán, số lượng đã bán
/// - Giá tiền định dạng VND Tabular Figures
/// - Nút thao tác nhanh Xem quán / Thêm vào giỏ
/// - An toàn với responsive, không bị RenderFlex overflow trên màn hình 320px
class LangFoodHorizontalProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onShopTap;
  final String? tag;
  final String? prepTime;
  final double rating;
  final String? reviewCount;

  const LangFoodHorizontalProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.onShopTap,
    this.tag,
    this.prepTime,
    this.rating = 4.8,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );
    final formattedPrice = currencyFormatter
        .format(product.price)
        .replaceAll(' ', '');

    final displayTag = tag ?? _resolveDefaultTag(product);
    final displayTime = prepTime ?? '15 phút';
    final displayReview = reviewCount ?? '(${product.id * 120 + 350}+ đã bán)';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LangFoodCard(
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Thumbnail với điểm đánh giá overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  child: Container(
                    width: 92,
                    height: 92,
                    color: theme.canvas,
                    child: _buildProductImage(),
                  ),
                ),
                // Rating badge overlay (Stitch: bottom-left)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Trạng thái quán đóng cửa
                if (!product.isShopOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'TẠM NGHỈ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // 2. Nội dung chi tiết
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tags row: Freeship KTX • 15 phút (Bảo vệ chống RenderFlex overflow)
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            displayTag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.tertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          displayTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 11,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Tên món ăn
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMd.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Quán ăn / mô tả KTX
                  Text(
                    product.shopName.isNotEmpty
                        ? 'KTX Khu B • ${product.shopName}'
                        : (product.description ??
                              'Món ngon sinh viên Làng Đại Học'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm.copyWith(
                      fontSize: 11,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Giá tiền và nút hành động (Bảo vệ tràn RenderFlex)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  formattedPrice,
                                  style: AppTypography.currencyDisplay.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayReview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      if ((onShopTap != null || onAddToCart != null) &&
                          product.isShopOpen)
                        PressScaleWidget(
                          onTap: onShopTap ?? onAddToCart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppTokens.radiusFull,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Xem quán',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 13,
                                  color: AppColors.primary,
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
          ],
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
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: AppColors.primary,
          size: 34,
        ),
      ),
    );
  }

  String _resolveDefaultTag(ProductModel p) {
    if (p.price <= 25000) return 'Combo sinh viên';
    if (p.name.toLowerCase().contains('gà')) return 'Freeship KTX';
    if (p.name.toLowerCase().contains('trà sữa')) return 'Mua 1 tặng 1 thạch';
    if (p.name.toLowerCase().contains('bún') ||
        p.name.toLowerCase().contains('phở')) {
      return 'Tặng trà tắc';
    }
    return 'Freeship 0đ';
  }
}
