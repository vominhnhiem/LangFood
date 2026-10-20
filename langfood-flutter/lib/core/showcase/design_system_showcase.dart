import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';
import '../widgets/langfood_bottom_sheet_shell.dart';
import '../widgets/langfood_buttons.dart';
import '../widgets/langfood_card.dart';
import '../widgets/langfood_category_chip.dart';
import '../widgets/langfood_empty_state.dart';
import '../widgets/langfood_floating_cart_pill.dart';
import '../widgets/langfood_loading_skeleton.dart';
import '../widgets/langfood_quantity_stepper.dart';
import '../widgets/langfood_search_field.dart';
import '../widgets/langfood_status_badge.dart';

/// Màn hình kiểm thử và trưng bày toàn bộ hệ thống Design System UI-01
/// Thiết kế chuẩn Apple Human Interface Guidelines kết hợp Material 3
/// Hỗ trợ kiểm thử Light / Dark Mode tức thì, các token màu, typography và components
class DesignSystemShowcase extends StatefulWidget {
  const DesignSystemShowcase({super.key});

  @override
  State<DesignSystemShowcase> createState() => _DesignSystemShowcaseState();
}

class _DesignSystemShowcaseState extends State<DesignSystemShowcase> {
  bool _isDarkMode = false;
  int _selectedCategoryIndex = 0;
  int _stepperCount = 2;
  final List<String> _categories = [
    'Tất cả',
    'Cơm trưa',
    'Trà sữa',
    'Bún/Phở',
    'Ăn vặt',
  ];
  final List<String> _emojis = ['🔥', '🍚', '🧋', '🍜', '🍟'];

  @override
  Widget build(BuildContext context) {
    final activeTheme = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    return Theme(
      data: activeTheme,
      child: Builder(
        builder: (themedContext) {
          final theme = themedContext.langFoodTheme;

          return Scaffold(
            backgroundColor: theme.canvas,
            appBar: AppBar(
              centerTitle: false,
              elevation: 0,
              backgroundColor: theme.card,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Design System Showcase',
                style: AppTypography.titleMd.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: InkWell(
                      onTap: () => setState(() => _isDarkMode = !_isDarkMode),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusFull,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isDarkMode
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isDarkMode ? 'Dark' : 'Light',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.marginMobile,
                vertical: AppTokens.spaceLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Info Card
                  _buildHeroIntro(theme),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 1. PALETTE & BRAND TOKENS
                  _buildSectionHeader(
                    '1. PALETTE & BRAND TOKENS',
                    'Bảng màu thương hiệu & hệ thống Semantic Surface',
                  ),
                  _buildColorPalette(theme),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 2. TYPOGRAPHY SCALE
                  _buildSectionHeader(
                    '2. TYPOGRAPHY SCALE',
                    'Hệ thống tỷ lệ chữ Inter · Dấu tiếng Việt chuẩn · Tabular Figures',
                  ),
                  _buildTypographyScale(theme),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 3. BUTTONS
                  _buildSectionHeader(
                    '3. BUTTONS (PRIMARY & SECONDARY)',
                    'Nút bấm tiêu chuẩn theo trạng thái Active, Loading, Disabled',
                  ),
                  _buildButtonsSection(theme),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 4. SEARCH FIELD
                  _buildSectionHeader(
                    '4. SEARCH FIELD',
                    'Thanh tìm kiếm bo tròn Squircle 12pt kèm voice search',
                  ),
                  const LangFoodSearchField(
                    hintText: 'Tìm kiếm món ăn, quán ngon Làng Đại Học...',
                  ),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 5. CATEGORY CHIPS
                  _buildSectionHeader(
                    '5. CATEGORY CHIPS (CAPSULE PILL)',
                    'Bộ lọc phân loại dạng con nhộng bo tròn Pill 9999pt',
                  ),
                  _buildCategoryChips(),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 6. QUANTITY STEPPER
                  _buildSectionHeader(
                    '6. QUANTITY STEPPER (TABULAR FIGURES)',
                    'Tăng giảm số lượng có chuyển đổi nút xóa khi = 1',
                  ),
                  _buildQuantityStepperSection(theme),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 7. STATUS BADGES
                  _buildSectionHeader(
                    '7. STATUS BADGES & PROMOTION PILLS',
                    'Huy hiệu trạng thái đơn hàng & nhãn khuyến mãi',
                  ),
                  _buildStatusBadges(),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 8. CARDS & ELEVATION
                  _buildSectionHeader(
                    '8. CARDS & ELEVATION',
                    'Thẻ món ăn, đổ bóng Level 1 và hiệu ứng nhấn Co giật nhẹ',
                  ),
                  _buildCardsSection(themedContext),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 9. LOADING SKELETONS
                  _buildSectionHeader(
                    '9. LOADING SKELETONS (SHIMMER)',
                    'Khung xương tải trang giảm giật layout khi tải API',
                  ),
                  _buildSkeletonsSection(themedContext),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 10. MODAL BOTTOM SHEET
                  _buildSectionHeader(
                    '10. MODAL BOTTOM SHEET',
                    'Sheet tùy chọn topping chuẩn Apple HIG với Drag Handle',
                  ),
                  LangFoodPrimaryButton(
                    text: 'Mở Bottom Sheet Tùy Biến Món',
                    icon: Icons.open_in_browser_rounded,
                    onPressed: () => _openBottomSheetDemo(themedContext),
                  ),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 11. EMPTY STATE
                  _buildSectionHeader(
                    '11. EMPTY STATE VIEW',
                    'Trạng thái giỏ hàng / danh sách trống kèm nút kêu gọi hành động',
                  ),
                  LangFoodCard(
                    child: LangFoodEmptyState(
                      title: 'Giỏ hàng của bạn đang trống',
                      message: 'Hãy khám phá các món ăn thơm ngon tại KTX để lấp đầy chiếc bụng đói nhé!',
                      buttonText: 'Khám phá món ngay',
                      onButtonPressed: () {},
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceLg),

                  // 12. FLOATING CART PILL
                  _buildSectionHeader(
                    '12. FLOATING CART PILL (STICKY LEVEL 3)',
                    'Thanh nổi giỏ hàng dính cố định góc dưới màn hình',
                  ),
                  LangFoodFloatingCartPill(
                    totalItemCount: 3,
                    totalPrice: 105000,
                    label: 'Cơm Gà Bà Tám',
                    onTap: () {},
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroIntro(LangFoodThemeExtension theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primaryDeep.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LangFood UI System',
                      style: AppTypography.titleMd.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      'Stitch V1 · Apple HIG Inspired · v1.0.0',
                      style: AppTypography.bodySm.copyWith(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hệ thống thành phần giao diện chuẩn hóa cho ứng dụng giao đồ ăn Làng Đại Học.',
            style: AppTypography.bodySm.copyWith(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(LangFoodThemeExtension theme) {
    final List<_ColorTokenItem> tokens = [
      _ColorTokenItem(
        name: 'Primary',
        hex: '#FF5722',
        role: 'Cam thương hiệu',
        color: AppColors.primary,
      ),
      _ColorTokenItem(
        name: 'Deep Crimson',
        hex: '#B02F00',
        role: 'Nhấn đậm Stitch',
        color: AppColors.primaryDeep,
      ),
      _ColorTokenItem(
        name: 'Accent Amber',
        hex: '#FF9800',
        role: 'Nổi bật / Giảm giá',
        color: AppColors.accent,
      ),
      _ColorTokenItem(
        name: 'Success Apple',
        hex: '#34C759',
        role: 'Hoàn thành / Giao',
        color: AppColors.successApple,
      ),
      _ColorTokenItem(
        name: 'Canvas Surface',
        hex: _isDarkMode ? '#1C1C1E' : '#F2F2F7',
        role: 'Nền hệ thống iOS',
        color: theme.canvas,
        hasBorder: true,
      ),
      _ColorTokenItem(
        name: 'Card Surface',
        hex: _isDarkMode ? '#2C2C2E' : '#FFFFFF',
        role: 'Nền thẻ nội dung',
        color: theme.card,
        hasBorder: true,
      ),
      _ColorTokenItem(
        name: 'Text Primary',
        hex: _isDarkMode ? '#FFFFFF' : '#1C1C1E',
        role: 'Chữ tiêu đề chính',
        color: theme.textPrimary,
      ),
      _ColorTokenItem(
        name: 'Text Secondary',
        hex: '#8E8E93',
        role: 'Chữ mô tả phụ',
        color: theme.textSecondary,
      ),
    ];

    return LangFoodCard(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tokens.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.3,
        ),
        itemBuilder: (context, index) {
          final item = tokens[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.canvas.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.06),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: item.hasBorder || item.color == theme.card
                          ? Colors.grey.withOpacity(0.35)
                          : Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withOpacity(0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMd.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                      Text(
                        item.hex,
                        style: AppTypography.currencyDisplay.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                      Text(
                        item.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypographyScale(LangFoodThemeExtension theme) {
    return LangFoodCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTypeRow(
            tokenName: 'HEADLINE XL',
            specs: '34px · Bold · Line 1.21',
            sampleText: 'Headline XL (34px) - Ăn ngon KTX',
            style: AppTypography.headlineXl,
            theme: theme,
          ),
          _buildTypeRow(
            tokenName: 'HEADLINE LG',
            specs: '28px · Bold · Line 1.21',
            sampleText: 'Headline LG (28px) - Cơm Gà Xối Mỡ',
            style: AppTypography.headlineLg,
            theme: theme,
          ),
          _buildTypeRow(
            tokenName: 'HEADLINE MD',
            specs: '22px · SemiBold · Line 1.27',
            sampleText: 'Headline MD (22px) - Quán Ăn Làng Đại Học',
            style: AppTypography.headlineMd,
            theme: theme,
          ),
          _buildTypeRow(
            tokenName: 'TITLE MD',
            specs: '17px · SemiBold · iOS Standard',
            sampleText: 'Title MD (17px bold) - Giao tận phòng P.402',
            style: AppTypography.titleMd,
            theme: theme,
          ),
          _buildTypeRow(
            tokenName: 'BODY MD',
            specs: '15px · Regular · Line 1.33',
            sampleText:
                'Body MD (15px) - Đồ ăn nóng hổi, giao siêu tốc trong 15 phút.',
            style: AppTypography.bodyMd,
            theme: theme,
            textColor: theme.textSecondary,
          ),
          _buildTypeRow(
            tokenName: 'CURRENCY DISPLAY',
            specs: '18px · Bold · Tabular Figures',
            sampleText: 'Currency Display: 125.000₫ (Tabular Figures)',
            style: AppTypography.currencyDisplay,
            theme: theme,
            textColor: AppColors.primary,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeRow({
    required String tokenName,
    required String specs,
    required String sampleText,
    required TextStyle style,
    required LangFoodThemeExtension theme,
    Color? textColor,
    bool isLast = false,
  }) {
    final effectiveColor = textColor ?? theme.textPrimary;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tokenName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                specs,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textSecondary.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(sampleText, style: style.copyWith(color: effectiveColor)),
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey.withOpacity(0.15),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildButtonsSection(LangFoodThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LangFoodPrimaryButton(text: 'ĐẶT ĐƠN NGAY • 85.000₫', onPressed: () {}),
        const SizedBox(height: 12),
        LangFoodPrimaryButton(
          text: 'Đang gửi mã OTP...',
          isLoading: true,
          onPressed: () {},
        ),
        const SizedBox(height: 12),
        const LangFoodPrimaryButton(
          text: 'Nút bị vô hiệu hóa',
          onPressed: null,
        ),
        const SizedBox(height: 12),
        LangFoodSecondaryButton(
          text: 'Xem chi tiết thực đơn',
          icon: Icons.restaurant_menu_rounded,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LangFoodCategoryChip(
              label: _categories[i],
              emoji: _emojis[i],
              isSelected: _selectedCategoryIndex == i,
              onTap: () => setState(() => _selectedCategoryIndex = i),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuantityStepperSection(LangFoodThemeExtension theme) {
    final subtotal = _stepperCount * 45000;
    final formattedSubtotal = subtotal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return LangFoodCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cơm Gà Xối Mỡ',
                style: AppTypography.titleMd.copyWith(color: theme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                'Tổng: $formattedSubtotal₫',
                style: AppTypography.currencyDisplay.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          LangFoodQuantityStepper(
            value: _stepperCount,
            min: 1,
            max: 10,
            onChanged: (val) => setState(() => _stepperCount = val),
            onDelete: () => setState(() => _stepperCount = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadges() {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        LangFoodStatusBadge(
          label: 'Đang giao hàng',
          variant: StatusBadgeVariant.info,
          icon: Icons.delivery_dining_rounded,
        ),
        LangFoodStatusBadge(
          label: 'Đã hoàn thành',
          variant: StatusBadgeVariant.success,
          icon: Icons.check_circle_rounded,
        ),
        LangFoodStatusBadge(
          label: 'Đang chuẩn bị',
          variant: StatusBadgeVariant.warning,
          icon: Icons.soup_kitchen_rounded,
        ),
        LangFoodStatusBadge(
          label: 'Đã hủy đơn',
          variant: StatusBadgeVariant.error,
          icon: Icons.cancel_rounded,
        ),
        LangFoodStatusBadge(
          label: 'Giảm 20%',
          variant: StatusBadgeVariant.primary,
          icon: Icons.local_offer_rounded,
        ),
      ],
    );
  }

  Widget _buildCardsSection(BuildContext context) {
    return LangFoodCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: const Icon(
              Icons.rice_bowl_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cơm Gà Xối Mỡ Đặc Biệt', style: AppTypography.titleMd),
                const SizedBox(height: 3),
                Text(
                  'Đùi gà góc tư chiên giòn rụm',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '45.000₫',
                      style: AppTypography.currencyDisplay.copyWith(
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.add_circle_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonsSection(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          LangFoodLoadingSkeleton.cardSkeleton(context),
          const SizedBox(width: 12),
          LangFoodLoadingSkeleton.cardSkeleton(context),
        ],
      ),
    );
  }

  void _openBottomSheetDemo(BuildContext context) {
    LangFoodBottomSheetShell.show(
      context: context,
      title: 'Tùy biến món ăn',
      bottomAction: LangFoodPrimaryButton(
        text: 'Thêm vào giỏ hàng • 45.000₫',
        onPressed: () => Navigator.pop(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn kích cỡ & Topping:', style: AppTypography.titleMd),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text('Phần ăn tiêu chuẩn (1 đùi gà xối mỡ)'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text('Thêm cơm thêm (+5.000₫)'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text('Thêm canh rong biển (+10.000₫)'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ColorTokenItem {
  final String name;
  final String hex;
  final String role;
  final Color color;
  final bool hasBorder;

  const _ColorTokenItem({
    required this.name,
    required this.hex,
    required this.role,
    required this.color,
    this.hasBorder = false,
  });
}
