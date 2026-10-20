import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_loading_skeleton.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/product_option_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';

/// Bảng tùy biến món ăn cao cấp chuẩn thiết kế Stitch LF-03 (Medium) và LF-04 (Expanded)
/// - Trình bày qua DraggableScrollableSheet với 2 nấc snap: Medium (~55%) & Expanded (~92%)
/// - Căn chỉnh góc bo 28px chuẩn iOS continuous squircle
/// - Tùy chọn Size (Radio/Đơn) và Topping (Checkbox/Nhiều) với phản hồi Haptic
/// - Bộ đếm số lượng Tabular Figures chống giật layout
/// - Tính giá động theo thời gian thực (Base Price + Options) * Quantity
/// - Ghi chú cho quán kèm Quick Chips đặc quyền sinh viên KTX
/// - Thanh hành động dính đáy (Sticky CTA) an toàn với bàn phím và SafeArea
class FoodCustomizationSheet extends StatefulWidget {
  final ProductModel product;
  final int initialQuantity;
  final String? initialNote;
  final List<ProductOptionGroupModel>? customOptionGroups;
  final VoidCallback? onCartAdded;

  const FoodCustomizationSheet({
    super.key,
    required this.product,
    this.initialQuantity = 1,
    this.initialNote,
    this.customOptionGroups,
    this.onCartAdded,
  });

  /// Phương thức tĩnh mở Modal Bottom Sheet chuẩn
  static Future<bool?> show({
    required BuildContext context,
    required ProductModel product,
    int initialQuantity = 1,
    String? initialNote,
    List<ProductOptionGroupModel>? customOptionGroups,
    VoidCallback? onCartAdded,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      enableDrag: true,
      isDismissible: true,
      builder: (ctx) => FoodCustomizationSheet(
        product: product,
        initialQuantity: initialQuantity,
        initialNote: initialNote,
        customOptionGroups: customOptionGroups,
        onCartAdded: onCartAdded,
      ),
    );
  }

  @override
  State<FoodCustomizationSheet> createState() => _FoodCustomizationSheetState();
}

class _FoodCustomizationSheetState extends State<FoodCustomizationSheet> {
  late int _quantity;
  late final TextEditingController _noteController;
  late List<ProductOptionGroupModel> _optionGroups;
  bool _isSubmitting = false;

  // Quick Chips gợi ý cho sinh viên Làng Đại Học
  static const List<String> _quickNoteChips = [
    'Ít cay',
    'Da gà thật giòn',
    'Nhiều dưa leo',
    'Mắm riêng',
    'Giao sảnh KTX',
    'Muỗng đũa ăn liền',
  ];

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity > 0 ? widget.initialQuantity : 1;
    _noteController = TextEditingController(text: widget.initialNote ?? '');

    // Clone sâu option groups để bảo vệ tính bất biến của model gốc
    final sourceGroups =
        widget.customOptionGroups ?? widget.product.optionGroups;
    _optionGroups = sourceGroups.map((g) {
      return ProductOptionGroupModel(
        id: g.id,
        productId: g.productId,
        name: g.name,
        isMultiple: g.isMultiple,
        options: g.options.map((opt) {
          return ProductOptionModel(
            id: opt.id,
            groupId: opt.groupId,
            name: opt.name,
            price: opt.price,
            isSelected: opt.isSelected,
          );
        }).toList(),
      );
    }).toList();

    // Đối với nhóm chọn 1 (size/độ cay), nếu chưa có tùy chọn nào được chọn thì mặc định chọn cái đầu tiên
    for (final group in _optionGroups) {
      if (!group.isMultiple && group.options.isNotEmpty) {
        final hasSelection = group.options.any((o) => o.isSelected);
        if (!hasSelection) {
          group.options.first.isSelected = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // --- TÍNH TOÁN GIÁ TIỀN ĐỘNG ---

  double get _optionsExtraPerItem {
    double extra = 0.0;
    for (final group in _optionGroups) {
      for (final opt in group.options) {
        if (opt.isSelected) {
          extra += opt.price;
        }
      }
    }
    return extra;
  }

  double get _unitPrice => widget.product.price + _optionsExtraPerItem;

  double get _totalPrice => _unitPrice * _quantity;

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

  // --- TƯƠNG TÁC LỰA CHỌN OPTION ---

  void _selectSingleOption(
    ProductOptionGroupModel group,
    ProductOptionModel option,
  ) {
    AppHaptics.selection();
    setState(() {
      for (final opt in group.options) {
        opt.isSelected = (opt.id == option.id);
      }
    });
  }

  void _toggleMultipleOption(ProductOptionModel option) {
    AppHaptics.selection();
    setState(() {
      option.isSelected = !option.isSelected;
    });
  }

  void _adjustQuantity(int delta) {
    final newQty = _quantity + delta;
    if (newQty >= 1 && newQty <= 99) {
      AppHaptics.light();
      setState(() {
        _quantity = newQty;
      });
    }
  }

  void _appendQuickNote(String text) {
    AppHaptics.light();
    final current = _noteController.text.trim();
    if (current.isEmpty) {
      _noteController.text = text;
    } else if (!current.contains(text)) {
      _noteController.text = '$current, $text';
    }
    setState(() {});
  }

  void _clearNote() {
    AppHaptics.light();
    _noteController.clear();
    setState(() {});
  }

  // --- XỬ LÝ THÊM VÀO GIỎ HÀNG (CartProvider Integration) ---

  Future<void> _handleAddToCart() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Thu thập tên các tùy chọn đã chọn
      final List<String> selectedSummary = [];
      for (final group in _optionGroups) {
        for (final opt in group.options) {
          if (opt.isSelected) {
            final priceExtra = opt.price > 0
                ? ' (+${_formatVnd(opt.price)})'
                : '';
            selectedSummary.add('${opt.name}$priceExtra');
          }
        }
      }

      final String? optionsJson = selectedSummary.isNotEmpty
          ? selectedSummary.join(', ')
          : null;
      final String? note = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null;

      // Thêm vào giỏ qua CartProvider
      cartProvider.addToCart(
        product: widget.product,
        quantity: _quantity,
        note: note,
        selectedOptionsJson: optionsJson,
        userId: authProvider.user?.id,
      );

      AppHaptics.medium();

      // Đóng sheet và gọi callback
      if (mounted) {
        Navigator.pop(context, true);
        widget.onCartAdded?.call();

        // Hiển thị phản hồi SnackBar nổi tinh tế
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successApple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã thêm $_quantity x "${widget.product.name}" vào giỏ KTX!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2F3034),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thêm vào giỏ. Vui lòng thử lại!'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55, // Nấc Medium LF-03 (~55% viewport)
        minChildSize: 0.40,
        maxChildSize: 0.92, // Nấc Expanded LF-04 (~92% viewport)
        snap: true,
        snapSizes: const [0.55, 0.92],
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: AppTokens.shadowLevel3,
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                children: [
                  // 1. Thanh Grabber kéo thả (Apple HIG Handle)
                  _buildGrabHandle(theme, isDark),

                  // 2. Dish Quick Glance Header (Ảnh đại diện, tên món, giá cơ bản, nút đóng)
                  _buildDishHeader(theme, isDark),

                  // 3. Vùng nội dung cuộn (Tùy chọn, ghi chú, bảo đảm giao hàng)
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.marginMobile,
                        4,
                        AppTokens.marginMobile,
                        16,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (_optionGroups.isEmpty)
                          _buildEmptyOptionsCard(theme, isDark)
                        else
                          ..._buildOptionSections(theme, isDark),

                        const SizedBox(height: 12),

                        // Section: Ghi chú cho quán (Lời nhắn & Quick Chips)
                        _buildKitchenNoteSection(theme, isDark),

                        const SizedBox(height: 12),

                        // Section: Banner bảo đảm shipper KTX giao tận phòng
                        _buildCampusAssurancePill(theme, isDark),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // 4. Thanh hành động dính đáy (Sticky Action Bar: Stepper & CTA)
                  _buildStickyBottomBar(theme, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET SUB-COMPONENTS ---

  Widget _buildGrabHandle(LangFoodThemeExtension theme, bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 38,
        height: 4.5,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildDishHeader(LangFoodThemeExtension theme, bool isDark) {
    final basePriceStr = _formatVnd(widget.product.price);
    final categoryText = widget.product.categoryName ?? 'Món chính';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.marginMobile,
        4,
        AppTokens.marginMobile,
        12,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.borderSubtle, width: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh thumbnail món ăn bo góc squircle 16px
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  border: Border.all(color: theme.borderSubtle, width: 0.6),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildDishThumbnail(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                  child: const Text(
                    'KTX Top 1',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Tên món, phân loại, giá cơ bản
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        categoryText,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      basePriceStr,
                      style: AppTypography.currencyDisplay.copyWith(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.product.description != null &&
                        widget.product.description!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.product.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Nút đóng tròn xúc giác chuẩn Apple HIG
          PressScaleWidget(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: theme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishThumbnail() {
    if (widget.product.imageUrl != null &&
        widget.product.imageUrl!.isNotEmpty) {
      final imgUrl = widget.product.imageUrl!.startsWith('http')
          ? widget.product.imageUrl!
          : '${AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/${widget.product.imageUrl!.replaceAll(RegExp(r'^/'), '')}';

      return Image.network(
        imgUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const LangFoodLoadingSkeleton(width: 64, height: 64);
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderThumbnail(),
      );
    }
    return _buildPlaceholderThumbnail();
  }

  Widget _buildPlaceholderThumbnail() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        color: AppColors.primary,
        size: 26,
      ),
    );
  }

  Widget _buildEmptyOptionsCard(LangFoodThemeExtension theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: theme.borderSubtle, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.successApple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.successApple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Công thức chuẩn vị quán',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Món này được chế biến chuẩn theo định lượng. Bạn có thể thêm lời nhắn cho bếp ở dưới nhé!',
                  style: TextStyle(fontSize: 11, color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptionSections(LangFoodThemeExtension theme, bool isDark) {
    final List<Widget> sections = [];

    for (int i = 0; i < _optionGroups.length; i++) {
      final group = _optionGroups[i];
      sections.add(
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            border: Border.all(color: theme.borderSubtle, width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề nhóm tùy chọn
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: group.isMultiple
                                ? AppColors.tertiary
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${i + 1}. ${group.name}',
                            style: AppTypography.titleMd.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: group.isMultiple
                          ? AppColors.tertiary.withValues(alpha: 0.12)
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      group.isMultiple ? 'Tùy chọn' : 'Bắt buộc',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: group.isMultiple
                            ? AppColors.tertiary
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Danh sách tùy chọn
              ...group.options.map((opt) {
                return group.isMultiple
                    ? _buildCheckboxOptionTile(opt, theme, isDark)
                    : _buildRadioOptionTile(group, opt, theme, isDark);
              }),
            ],
          ),
        ),
      );
    }

    return sections;
  }

  // Tùy chọn đơn (Radio Button phong cách iOS HIG)
  Widget _buildRadioOptionTile(
    ProductOptionGroupModel group,
    ProductOptionModel option,
    LangFoodThemeExtension theme,
    bool isDark,
  ) {
    final isSelected = option.isSelected;
    final priceStr = option.price > 0 ? '+${_formatVnd(option.price)}' : '+0₫';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PressScaleWidget(
        onTap: () => _selectSingleOption(group, option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                : theme.card,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.primary : theme.borderSubtle,
              width: isSelected ? 1.4 : 0.6,
            ),
          ),
          child: Row(
            children: [
              // Custom iOS Tactile Radio Ring
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : theme.textSecondary.withValues(alpha: 0.4),
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: SizedBox(
                          width: 6,
                          height: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),

              // Tên tùy chọn
              Expanded(
                child: Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
              ),

              // Giá chênh lệch
              Text(
                priceStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: option.price > 0
                      ? AppColors.primary
                      : theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tùy chọn nhiều (Checkbox phong cách iOS HIG)
  Widget _buildCheckboxOptionTile(
    ProductOptionModel option,
    LangFoodThemeExtension theme,
    bool isDark,
  ) {
    final isSelected = option.isSelected;
    final priceStr = '+${_formatVnd(option.price)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: PressScaleWidget(
        onTap: () => _toggleMultipleOption(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                : theme.card,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.primary : theme.borderSubtle,
              width: isSelected ? 1.4 : 0.6,
            ),
          ),
          child: Row(
            children: [
              // Custom iOS Tactile Checkbox Squircle
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : theme.textSecondary.withValues(alpha: 0.4),
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 10),

              // Tên tùy chọn
              Expanded(
                child: Text(
                  option.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
              ),

              // Giá chênh lệch
              Text(
                priceStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section: Lời nhắn cho bếp & Quick Chips
  Widget _buildKitchenNoteSection(LangFoodThemeExtension theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: theme.borderSubtle, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lời nhắn cho bếp',
                style: AppTypography.titleMd.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                'Không bắt buộc',
                style: TextStyle(fontSize: 10, color: theme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick Chips dành riêng cho sinh viên KTX
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickNoteChips.map((chipText) {
              return PressScaleWidget(
                onTap: () => _appendQuickNote(chipText),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    border: Border.all(color: theme.borderSubtle, width: 0.6),
                  ),
                  child: Text(
                    '+ $chipText',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Ô nhập ghi chú tự do
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(color: theme.borderSubtle, width: 0.6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    style: TextStyle(fontSize: 12.5, color: theme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Ít cay, da giòn, dưa leo cắt mỏng...',
                      hintStyle: TextStyle(
                        fontSize: 11.5,
                        color: theme.textSecondary.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_noteController.text.isNotEmpty)
                  GestureDetector(
                    onTap: _clearNote,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.cancel_rounded,
                        color: theme.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Banner bảo chứng shipper KTX giao tận phòng
  Widget _buildCampusAssurancePill(LangFoodThemeExtension theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.22),
          width: 0.6,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.electric_moped_rounded,
            color: AppColors.secondary,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Shipper sinh viên giao tận cửa phòng KTX Khu A & B, bảo đảm cơm còn nóng hổi.',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sticky Bottom Action Bar (Stepper + CTA)
  Widget _buildStickyBottomBar(LangFoodThemeExtension theme, bool isDark) {
    final totalPriceStr = _formatVnd(_totalPrice);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.marginMobile,
        10,
        AppTokens.marginMobile,
        12,
      ),
      decoration: BoxDecoration(
        color: theme.card,
        border: Border(top: BorderSide(color: theme.borderSubtle, width: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tactile Stepper [-] [ Qty ] [+]
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: theme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: theme.borderSubtle, width: 0.6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PressScaleWidget(
                  onTap: _quantity > 1 ? () => _adjustQuantity(-1) : null,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 16,
                      color: _quantity > 1
                          ? theme.textPrimary
                          : theme.textSecondary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 30),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$_quantity',
                    style: AppTypography.counterDisplay.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                PressScaleWidget(
                  onTap: _quantity < 99 ? () => _adjustQuantity(1) : null,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: _quantity < 99
                          ? AppColors.primary
                          : theme.textSecondary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Primary CTA Button: "Thêm vào giỏ • [Tổng tiền]"
          Expanded(
            child: PressScaleWidget(
              onTap: _isSubmitting ? null : _handleAddToCart,
              child: AnimatedContainer(
                duration: AppMotion.durationFast,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  boxShadow: AppTokens.shadowPrimaryButton,
                ),
                child: _isSubmitting
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Thêm vào giỏ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '•',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                totalPriceStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
