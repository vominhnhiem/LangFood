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

/// Thẻ Deal chớp nhoáng nghỉ trưa ⚡ chuẩn thiết kế Stitch LF-01
/// - Bố cục dọc chiều rộng 164px cuộn ngang
/// - Badge giảm giá -35% và thời gian chuẩn bị 15p
/// - Giá khuyến mãi và giá gốc gạch ngang
/// - Nút thêm nhanh dấu cộng tròn
/// - Chống RenderFlex overflow khi màn hình nhỏ hoặc text scaling cao
class LangFoodDealCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final int discountPercent;
  final String prepTime;

  const LangFoodDealCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.discountPercent = 25,
    this.prepTime = '15p',
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );

    // Tính giá khuyến mãi và giá gốc
    final double originalPrice = product.price > 0 ? product.price : 40000;
    final double dealPrice = originalPrice * (1.0 - (discountPercent / 100.0));

    final formattedDealPrice = currencyFormatter
        .format(dealPrice)
        .replaceAll(' ', '');
    final formattedOriginalPrice = currencyFormatter
        .format(originalPrice)
        .replaceAll(' ', '');

    return Container(
      width: 164,
      margin: const EdgeInsets.only(right: 12),
      child: LangFoodCard(
        padding: const EdgeInsets.all(10),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Hình ảnh với badge giảm giá và thời gian
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    color: theme.canvas,
                    child: _buildProductImage(),
                  ),
                ),
                // Badge giảm giá đỏ (-35%)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '-$discountPercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Thời gian giao hàng (15p)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      prepTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 2. Tên món ăn & Tên quán
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.shopName.isNotEmpty
                      ? product.shopName
                      : 'Quán quen KTX',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 3. Giá tiền và nút thêm nhanh (+)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formattedDealPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.currencyDisplay.copyWith(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        formattedOriginalPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.textSecondary.withValues(alpha: 0.7),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                PressScaleWidget(
                  onTap: () {
                    AppHaptics.light();
                    onAddToCart();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
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
        child: Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 30),
      ),
    );
  }
}
