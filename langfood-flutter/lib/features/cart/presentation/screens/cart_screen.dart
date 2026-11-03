import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../config/config_url.dart';
import '../../../../data/models/checkout_selection.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_quantity_stepper.dart';
import '../../../../data/models/cart_item_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../tracking/presentation/screens/location_picker_screen.dart';

/// Màn hình Giỏ hàng cao cấp theo bản vẽ Google Stitch LF-05
/// - Thiết kế Apple HIG kết hợp Material 3
/// - Phân nhóm giỏ hàng theo từng quán ăn (Grouped Restaurant Cart)
/// - Hỗ trợ quy tắc đơn ghép KTX tối đa 2 quán trong cùng Khu B
/// - Điều khiển số lượng bằng LangFoodQuantityStepper phản hồi xúc giác (Haptic)
/// - Tóm tắt chi phí minh bạch, hiển thị rõ ràng phụ phí giao hàng
/// - Thanh thanh toán nổi dính đáy (Sticky Floating Apple-HIG Checkout Bar)
/// - Trạng thái rỗng (Empty State), tải dữ liệu (Skeleton) và cảnh báo lỗi
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Bộ theo dõi các món được người dùng tích chọn để thanh toán (mặc định chọn tất cả)
  final Set<CartItemModel> _selectedItems = {};
  final Set<CartItemModel> _knownItems = {};
  bool _hasInitializedSelection = false;

  // Ghi chú riêng cho từng quán ăn theo shopId
  final Map<int, TextEditingController> _shopNoteControllers = {};

  // Trạng thái voucher campus ghép đơn
  static const bool _isVoucherApplied = false;

  @override
  void dispose() {
    for (final controller in _shopNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(amount).replaceAll(RegExp(r'[\s\u00A0]+'), '');
  }

  TextEditingController _getNoteController(int shopId) {
    if (!_shopNoteControllers.containsKey(shopId)) {
      _shopNoteControllers[shopId] = TextEditingController();
    }
    return _shopNoteControllers[shopId]!;
  }

  void _syncSelectedItems(List<CartItemModel> currentItems) {
    if (!_hasInitializedSelection) {
      _selectedItems.clear();
      _selectedItems.addAll(currentItems);
      _knownItems.clear();
      _knownItems.addAll(currentItems);
      _hasInitializedSelection = true;
    } else {
      // Loại bỏ các món đã bị xóa khỏi CartProvider
      _selectedItems.removeWhere((item) => !currentItems.contains(item));
      _knownItems.removeWhere((item) => !currentItems.contains(item));
      // Nếu có món hoàn toàn mới (chưa từng thấy trong _knownItems), mặc định tích chọn
      for (final item in currentItems) {
        if (!_knownItems.contains(item)) {
          _knownItems.add(item);
          _selectedItems.add(item);
        }
      }
    }
  }

  void _toggleSelectAll(bool isChecked, List<CartItemModel> allItems) {
    AppHaptics.selection();
    setState(() {
      if (isChecked) {
        _selectedItems.addAll(allItems);
      } else {
        _selectedItems.clear();
      }
    });
  }

  void _toggleShopSelection(
    int shopId,
    List<CartItemModel> shopItems,
    bool isChecked,
  ) {
    AppHaptics.selection();
    setState(() {
      if (isChecked) {
        _selectedItems.addAll(shopItems);
      } else {
        _selectedItems.removeAll(shopItems);
      }
    });
  }

  void _toggleItemSelection(CartItemModel item, bool isChecked) {
    AppHaptics.selection();
    setState(() {
      if (isChecked) {
        _selectedItems.add(item);
      } else {
        _selectedItems.remove(item);
      }
    });
  }

  // Hộp thoại xác nhận xóa toàn bộ giỏ hàng
  void _confirmClearCart(
    BuildContext context,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    AppHaptics.medium();
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = ctx.langFoodTheme;
        return AlertDialog(
          backgroundColor: theme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.errorApple,
                size: 26,
              ),
              const SizedBox(width: AppTokens.spaceSm),
              Text(
                'Xóa tất cả món?',
                style: AppTypography.titleMd.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Toàn bộ món ăn đang có trong giỏ hàng sẽ bị xóa. Bạn có chắc chắn muốn xóa không?',
            style: AppTypography.bodyMd.copyWith(color: theme.textSecondary),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceMd,
            vertical: AppTokens.spaceSm,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Giữ lại',
                style: AppTypography.labelLg.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.errorApple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                cartProvider.clearCart(authProvider.user?.id);
                setState(() {
                  _selectedItems.clear();
                  _knownItems.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tất cả món trong giỏ hàng'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Xóa hết',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Hộp thoại xác nhận xóa từng món ăn
  void _confirmDeleteItem(
    BuildContext context,
    CartItemModel item,
    CartProvider cartProvider,
    AuthProvider authProvider,
  ) {
    AppHaptics.light();
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = ctx.langFoodTheme;
        return AlertDialog(
          backgroundColor: theme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          ),
          title: Text(
            'Xóa món ăn',
            style: AppTypography.titleMd.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Bạn có muốn xóa "${item.product.name}" khỏi giỏ hàng không?',
            style: AppTypography.bodyMd.copyWith(color: theme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy', style: TextStyle(color: theme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                cartProvider.removeItem(item, authProvider.user?.id);
                setState(() => _selectedItems.remove(item));
              },
              child: const Text(
                'Xóa',
                style: TextStyle(
                  color: AppColors.errorApple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startCheckoutFlow(
    BuildContext context, {
    required String shopLabel,
    required double amount,
    required int count,
    List<CartItemModel>? items,
  }) async {
    final selected = items ?? _selectedItems.toList();
    if (selected.isEmpty) return;
    final selection = CheckoutSelection(
      selected,
      shopNotes: {
        for (final entry in _shopNoteControllers.entries)
          entry.key: entry.value.text.trim(),
      },
    );
    final location = await Navigator.push<CampusDeliveryLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(returnResult: true),
      ),
    );
    if (location == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CheckoutScreen(deliveryLocation: location, selection: selection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    final allItems = cartProvider.items;
    _syncSelectedItems(allItems);

    final shopMap = cartProvider.itemsByShop;
    final totalSelectedCount = _selectedItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    // Tính toán tổng tiền của các món được chọn
    final rawSelectedSubtotal = _selectedItems.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    // Phụ phí giao hàng KTX: Ghép 2 quán là 5.000₫, 1 quán là 0₫ (Freeship KTX)
    final selectedShopsCount = _selectedItems
        .map((item) => item.product.shopId > 0 ? item.product.shopId : 999)
        .toSet()
        .length;
    late final double configuredFee;
    try {
      configuredFee = ConfigUrl.shippingFee;
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Giỏ hàng của bạn')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chưa cấu hình phí giao hàng. Vui lòng kiểm tra cấu hình ứng dụng.',
            ),
          ),
        ),
      );
    }
    final double deliveryFee = selectedShopsCount * configuredFee;
    const double voucherDiscount = 0;
    final double checkoutTotal =
        (rawSelectedSubtotal + deliveryFee - voucherDiscount).clamp(
          0.0,
          double.infinity,
        );

    final bool isAllSelected =
        allItems.isNotEmpty && _selectedItems.length == allItems.length;

    return Scaffold(
      backgroundColor: theme.canvas,
      appBar: AppBar(
        backgroundColor: isDark
            ? theme.card
            : Colors.white.withValues(alpha: 0.95),
        elevation: 0.5,
        centerTitle: true,
        scrolledUnderElevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: theme.textPrimary,
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Giỏ hàng của bạn',
                style: AppTypography.titleMd.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (cartProvider.totalItemsCount > 0) ...[
                const SizedBox(width: AppTokens.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: Text(
                    '${cartProvider.totalItemsCount}',
                    style: AppTypography.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (allItems.isNotEmpty)
            TextButton(
              onPressed: () =>
                  _confirmClearCart(context, cartProvider, authProvider),
              child: Text(
                'Xóa',
                style: AppTypography.labelLg.copyWith(
                  color: AppColors.errorApple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: allItems.isEmpty
          ? _buildEmptyState(context)
          : Stack(
              children: [
                // Danh sách cuộn chứa các nhóm quán và thông tin thanh toán
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.marginMobile,
                    AppTokens.spaceSm,
                    AppTokens.marginMobile,
                    150.0, // Chừa khoảng trống an toàn cho Sticky Checkout Bar
                  ),
                  children: [
                    // Banner thông báo quy tắc ghép đơn KTX (Multi-shop Rule)
                    _buildCampusNoticeBanner(
                      context,
                      selectedShopsCount: selectedShopsCount,
                    ),
                    const SizedBox(height: AppTokens.spaceMd),

                    // Danh sách các nhóm quán ăn
                    ...shopMap.entries.map((entry) {
                      final shopId = entry.key;
                      final items = entry.value;
                      final shopName = cartProvider.getShopName(shopId);
                      final shopSubtotal = cartProvider.getShopSubtotal(shopId);

                      return _buildShopGroupCard(
                        context,
                        shopId: shopId,
                        shopName: shopName,
                        shopItems: items,
                        shopSubtotal: shopSubtotal,
                        cartProvider: cartProvider,
                        authProvider: authProvider,
                      );
                    }),

                    // Thẻ tối ưu đơn hàng & Voucher sinh viên KTX
                    _buildPricingBreakdownCard(
                      context,
                      rawSubtotal: rawSelectedSubtotal,
                      deliveryFee: deliveryFee,
                      voucherDiscount: voucherDiscount,
                      totalSelectedCount: totalSelectedCount,
                      selectedShopsCount: selectedShopsCount,
                    ),
                  ],
                ),

                // Sticky Floating Apple-HIG Checkout Bar cố định ở đáy
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildStickyCheckoutBar(
                    context,
                    isAllSelected: isAllSelected,
                    allItems: allItems,
                    totalSelectedCount: totalSelectedCount,
                    checkoutTotal: checkoutTotal,
                    rawSelectedSubtotal: rawSelectedSubtotal,
                    selectedShopsCount: selectedShopsCount,
                  ),
                ),
              ],
            ),
    );
  }

  // 1. Trạng thái Giỏ hàng trống (Empty State) theo chuẩn Stitch LF-05
  Widget _buildEmptyState(BuildContext context) {
    final theme = context.langFoodTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceXl,
          vertical: AppTokens.spaceLg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lunch_dining_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppTokens.spaceLg),
            Text(
              'Giỏ hàng KTX đang trống!',
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm.copyWith(
                color: theme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.spaceSm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 290),
              child: Text(
                'Bạn chưa chọn món nào. Khám phá thực đơn và thêm món vào giỏ nhé!',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: theme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceXl),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: () {
                  AppHaptics.light();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.explore_rounded, size: 20),
                label: Text(
                  'Khám phá món ngon KTX',
                  style: AppTypography.labelLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Banner thông báo quy tắc ghép đơn đa quán KTX
  Widget _buildCampusNoticeBanner(
    BuildContext context, {
    required int selectedShopsCount,
  }) {
    final theme = context.langFoodTheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.electric_moped_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Giỏ hàng theo quán',
                      style: AppTypography.titleMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusFull,
                        ),
                      ),
                      child: Text(
                        'Đơn riêng từng quán',
                        style: AppTypography.labelSm.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Các món được nhóm theo quán. Mỗi quán tạo một đơn, có phí giao và trạng thái riêng.',
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Thẻ nhóm sản phẩm theo quán ăn (Grouped Restaurant Card)
  Widget _buildShopGroupCard(
    BuildContext context, {
    required int shopId,
    required String shopName,
    required List<CartItemModel> shopItems,
    required double shopSubtotal,
    required CartProvider cartProvider,
    required AuthProvider authProvider,
  }) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    final isShopAllSelected = shopItems.every(
      (item) => _selectedItems.contains(item),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
        boxShadow: isDark ? AppTokens.shadowLevel1Dark : AppTokens.shadowLevel1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề quán (Shop Header)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceMd,
              vertical: 12,
            ),
            color: isDark ? theme.surfaceContainerLow : const Color(0xFFFBFBFC),
            child: Row(
              children: [
                // Checkbox chọn toàn bộ quán
                InkWell(
                  onTap: () => _toggleShopSelection(
                    shopId,
                    shopItems,
                    !isShopAllSelected,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isShopAllSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isShopAllSelected
                              ? AppColors.primary
                              : theme.textSecondary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: isShopAllSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSm),

                // Avatar quán
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSm),

                // Tên quán & thông tin meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shopName,
                              style: AppTypography.titleMd.copyWith(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Phí giao tính tại thanh toán',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            'Chọn điểm nhận',
                            style: AppTypography.labelSm.copyWith(
                              color: theme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Nút "Thêm món"
                InkWell(
                  onTap: () {
                    AppHaptics.light();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Thêm món',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.borderSubtle),

          // Danh sách các món của quán này
          ...shopItems.map((item) {
            final isItemSelected = _selectedItems.contains(item);
            return _buildCartItemRow(
              context,
              item: item,
              isSelected: isItemSelected,
              cartProvider: cartProvider,
              authProvider: authProvider,
            );
          }),

          Divider(height: 1, color: theme.borderSubtle),

          // Phần chân của nhóm quán: Ghi chú & Tạm tính
          Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trường nhập ghi chú cho quán
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.surfaceContainerLow
                        : const Color(0xFFF7F7F9),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    border: Border.all(color: theme.borderSubtle, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 20,
                        color: theme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _getNoteController(shopId),
                          cursorColor: AppColors.primary,
                          style: AppTypography.bodySm.copyWith(
                            color: theme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ghi chú cho quán (ví dụ: cơm mềm, sốt để riêng)...',
                            hintStyle: AppTypography.bodySm.copyWith(
                              color: theme.textSecondary.withValues(alpha: 0.7),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spaceSm),

                // Tạm tính và nút đặt đơn riêng cho quán này (IB-01 resolution)
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tạm tính quán',
                          style: AppTypography.labelSm.copyWith(
                            color: theme.textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(shopSubtotal),
                          style: AppTypography.titleMd.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMd,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        _startCheckoutFlow(
                          context,
                          shopLabel: shopName,
                          items: shopItems,
                          amount: shopSubtotal,
                          count: shopItems.fold<int>(
                            0,
                            (s, i) => s + i.quantity,
                          ),
                        );
                      },
                      child: Text(
                        'Đặt đơn quán này',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
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
    );
  }

  // 4. Hàng hiển thị chi tiết từng món ăn trong giỏ
  Widget _buildCartItemRow(
    BuildContext context, {
    required CartItemModel item,
    required bool isSelected,
    required CartProvider cartProvider,
    required AuthProvider authProvider,
  }) {
    final theme = context.langFoodTheme;

    final hasOptions =
        item.selectedOptionsJson != null &&
        item.selectedOptionsJson!.trim().isNotEmpty;
    final hasNote = item.note != null && item.note!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMd,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox chọn món
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkWell(
              onTap: () => _toggleItemSelection(item, !isSelected),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : theme.textSecondary.withValues(alpha: 0.4),
                      width: 1.5,
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
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spaceSm),

          // Ảnh món ăn với thumbnail bo góc 14px
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 72,
              height: 72,
              child:
                  item.product.imageUrl != null &&
                      item.product.imageUrl!.isNotEmpty
                  ? Image.network(
                      item.product.imageUrl!.startsWith('http')
                          ? item.product.imageUrl!
                          : '${AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/${item.product.imageUrl!.replaceAll(RegExp(r'^/'), '')}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildItemPlaceholder(theme),
                    )
                  : _buildItemPlaceholder(theme),
            ),
          ),
          const SizedBox(width: AppTokens.spaceSm),

          // Tên món, options, note và Stepper
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên món và nút Xóa món
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: AppTypography.titleMd.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _confirmDeleteItem(
                        context,
                        item,
                        cartProvider,
                        authProvider,
                      ),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),

                // Hiển thị cấu hình Size / Topping đã lưu
                if (hasOptions) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.selectedOptionsJson!,
                    style: AppTypography.bodySm.copyWith(
                      color: theme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Hiển thị ghi chú món
                if (hasNote) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '"${item.note}"',
                      style: AppTypography.labelSm.copyWith(
                        color: Colors.orange.shade800,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Giá tiền và Stepper tăng/giảm
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Text(
                      _formatCurrency(item.totalPrice),
                      style: AppTypography.currencyDisplay.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    LangFoodQuantityStepper(
                      value: item.quantity,
                      min: 1,
                      max: 99,
                      onChanged: (newQty) {
                        AppHaptics.light();
                        final delta = newQty - item.quantity;
                        cartProvider.updateQuantity(
                          item,
                          delta,
                          authProvider.user?.id,
                        );
                      },
                      onDelete: () {
                        _confirmDeleteItem(
                          context,
                          item,
                          cartProvider,
                          authProvider,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemPlaceholder(LangFoodThemeExtension theme) {
    return Container(
      color: theme.surfaceContainerLow,
      child: const Center(
        child: Icon(Icons.fastfood_rounded, color: Colors.grey, size: 28),
      ),
    );
  }

  // 5. Thẻ tối ưu đơn hàng & Tóm tắt chi phí (Pricing Breakdown)
  Widget _buildPricingBreakdownCard(
    BuildContext context, {
    required double rawSubtotal,
    required double deliveryFee,
    required double voucherDiscount,
    required int totalSelectedCount,
    required int selectedShopsCount,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.langFoodTheme.card,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết thanh toán',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildSummaryRow(
          textColor: context.langFoodTheme.textPrimary,
          label: 'Tiền món ($totalSelectedCount món)',
          value: _formatCurrency(rawSubtotal),
        ),
        _buildSummaryRow(
          textColor: context.langFoodTheme.textPrimary,
          label: 'Phí giao ($selectedShopsCount đơn)',
          value: _formatCurrency(deliveryFee),
        ),
        if (selectedShopsCount > 1)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Mỗi quán tạo một đơn và tính phí giao riêng.'),
          ),
      ],
    ),
  );

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required Color textColor,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.bodySm.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 6. Sticky Floating Apple-HIG Checkout Bar cố định ở đáy
  Widget _buildStickyCheckoutBar(
    BuildContext context, {
    required bool isAllSelected,
    required List<CartItemModel> allItems,
    required int totalSelectedCount,
    required double checkoutTotal,
    required double rawSelectedSubtotal,
    required int selectedShopsCount,
  }) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? theme.surfaceContainerLow.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94),
            boxShadow: AppTokens.shadowLevel3,
            border: Border(
              top: BorderSide(color: theme.borderSubtle, width: 0.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            AppTokens.marginMobile,
            10.0,
            AppTokens.marginMobile,
            MediaQuery.of(context).padding.bottom + 10.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thông báo cam kết giao hàng sinh viên KTX
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Giao hàng tới điểm nhận đã chọn',
                            style: AppTypography.labelSm.copyWith(
                              color: theme.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Phí theo quán',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Dòng điều khiển chính: Chọn tất cả + Giá + Nút CTA
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                  final isCompact =
                      constraints.maxWidth < (380 * textScale) ||
                      textScale >= 1.2;
                  final selectAllWidget = InkWell(
                    onTap: () => _toggleSelectAll(!isAllSelected, allItems),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isAllSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isAllSelected
                                    ? AppColors.primary
                                    : theme.textSecondary.withValues(
                                        alpha: 0.4,
                                      ),
                                width: 1.5,
                              ),
                            ),
                            child: isAllSelected
                                ? const Icon(
                                    Icons.done_all_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tất cả',
                            style: AppTypography.labelSm.copyWith(
                              color: theme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  final totalWidget = Column(
                    crossAxisAlignment: isCompact
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: isCompact
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Tổng: ',
                              style: AppTypography.labelSm.copyWith(
                                color: theme.textSecondary,
                              ),
                            ),
                            Text(
                              _formatCurrency(checkoutTotal),
                              style: AppTypography.headlineSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedShopsCount >= 2 && _isVoucherApplied)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: isCompact
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Text(
                            'Tiết kiệm 35.000₫',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  );

                  final ctaWidget = ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: totalSelectedCount > 0
                          ? AppColors.primary
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      elevation: totalSelectedCount > 0 ? 3 : 0,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: totalSelectedCount > 0
                        ? () {
                            final shopLabel = selectedShopsCount > 1
                                ? 'Đơn ghép $selectedShopsCount quán KTX'
                                : 'Tất cả các món đã chọn';
                            _startCheckoutFlow(
                              context,
                              shopLabel: shopLabel,
                              amount: checkoutTotal,
                              count: totalSelectedCount,
                            );
                          }
                        : null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: isCompact
                            ? MainAxisSize.max
                            : MainAxisSize.min,
                        children: [
                          Text(
                            'Thanh toán ($totalSelectedCount)',
                            style: AppTypography.titleMd.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            selectAllWidget,
                            const SizedBox(width: 8),
                            Expanded(child: totalWidget),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ctaWidget,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      selectAllWidget,
                      const SizedBox(width: AppTokens.spaceSm),
                      Expanded(child: totalWidget),
                      const SizedBox(width: AppTokens.spaceSm),
                      Flexible(child: SizedBox(height: 48, child: ctaWidget)),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
