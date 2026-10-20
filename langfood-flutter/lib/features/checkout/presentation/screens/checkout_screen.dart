import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../data/models/order_test_model.dart';
import '../../../../data/services/order_test_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';

import 'package:flutter_map/flutter_map.dart';

import '../../../tracking/presentation/screens/live_tracking_screen.dart';
import '../../../tracking/presentation/screens/location_picker_screen.dart';

/// Màn hình Thanh toán cao cấp Stitch LF-07 (Checkout / Order Confirmation)
/// - Thẻ thông tin điểm giao hàng KTX ĐHQG (nút Thay đổi quay lại LocationPicker)
/// - Tóm tắt chi tiết các món trong đơn hàng (hỗ trợ đơn lẻ và đơn ghép KTX)
/// - Bộ chọn phương thức thanh toán (LangFood Pay, MoMo, VietQR, ZaloPay, Tiền mặt COD)
/// - Thẻ voucher sinh viên KTX (LANGFOODPAIR, FREESHIPKTX)
/// - Bảng tính chi phí minh bạch kèm badge chúc mừng tiết kiệm
/// - Thanh tác vụ ghim đáy (Sticky Bottom Action Bar) chống double-tap
/// - Modal trạng thái: Đang xử lý -> Thành công -> Điều hướng sang LiveTrackingScreen
/// - Hiển thị nhãn minh bạch "Chế độ thử nghiệm" cho luồng OrderTest hiện hành
class CheckoutScreen extends StatefulWidget {
  final CampusDeliveryLocation deliveryLocation;
  final TileProvider? tileProvider;

  const CheckoutScreen({
    super.key,
    required this.deliveryLocation,
    this.tileProvider,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late CampusDeliveryLocation _currentLocation;

  // Phương thức thanh toán được chọn: 'langfood', 'momo', 'vietqr', 'zalopay', 'cod'
  String _selectedPaymentMethod = 'langfood';

  // Trạng thái voucher
  bool _isPairVoucherApplied = true;
  bool _isFreeshipVoucherApplied = true;

  // Trạng thái xử lý thanh toán và tạo đơn
  bool _isSubmittingOrder = false;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.deliveryLocation;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(amount).replaceAll(RegExp(r'[\s\u00A0]+'), '');
  }

  void _onChangeLocation() async {
    AppHaptics.light();
    final updated = await Navigator.push<CampusDeliveryLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _currentLocation,
          tileProvider: widget.tileProvider,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentLocation = updated;
      });
    }
  }

  void _openPaymentMethodBottomSheet() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = ctx.langFoodTheme;
        final isDark = ctx.isDarkMode;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: theme.card,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: AppTokens.shadowLevel3,
              ),
              padding: EdgeInsets.fromLTRB(
                AppTokens.marginMobile,
                12,
                AppTokens.marginMobile,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grab handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          AppTokens.radiusFull,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phương thức thanh toán',
                            style: AppTypography.headlineSm.copyWith(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Áp dụng ưu đãi sinh viên Làng Đại Học',
                            style: AppTypography.bodySm.copyWith(
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: theme.textSecondary,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Ví LangFood Pay
                  _buildPaymentRadioTile(
                    theme: theme,
                    isDark: isDark,
                    keyName: 'langfood',
                    title: 'Ví sinh viên LangFood Pay',
                    subTitle: 'Số dư khả dụng: 150.000₫ • Hoàn 5% vào ví',
                    badgeText: 'Ưu đãi -5K',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.primary,
                    currentChoice: _selectedPaymentMethod,
                    onTap: () {
                      setSheetState(() => _selectedPaymentMethod = 'langfood');
                      setState(() => _selectedPaymentMethod = 'langfood');
                    },
                  ),
                  const SizedBox(height: 8),

                  // Option 2: MoMo KTX Express
                  _buildPaymentRadioTile(
                    theme: theme,
                    isDark: isDark,
                    keyName: 'momo',
                    title: 'Ví MoMo KTX Express',
                    subTitle: 'Liên kết 1-chạm MoMo Sinh Viên',
                    badgeText: '1-chạm',
                    icon: Icons.flash_on_rounded,
                    iconColor: const Color(0xFFA50064),
                    currentChoice: _selectedPaymentMethod,
                    onTap: () {
                      setSheetState(() => _selectedPaymentMethod = 'momo');
                      setState(() => _selectedPaymentMethod = 'momo');
                    },
                  ),
                  const SizedBox(height: 8),

                  // Option 3: VietQR Pro
                  _buildPaymentRadioTile(
                    theme: theme,
                    isDark: isDark,
                    keyName: 'vietqr',
                    title: 'VietQR Pro / Chuyển khoản',
                    subTitle: 'Quét mã QR ngân hàng 24/7 (0đ phí)',
                    icon: Icons.qr_code_2_rounded,
                    iconColor: AppColors.secondary,
                    currentChoice: _selectedPaymentMethod,
                    onTap: () {
                      setSheetState(() => _selectedPaymentMethod = 'vietqr');
                      setState(() => _selectedPaymentMethod = 'vietqr');
                    },
                  ),
                  const SizedBox(height: 8),

                  // Option 4: ZaloPay
                  _buildPaymentRadioTile(
                    theme: theme,
                    isDark: isDark,
                    keyName: 'zalopay',
                    title: 'Ví ZaloPay',
                    subTitle: 'Thanh toán qua ứng dụng Zalo',
                    icon: Icons.account_balance_rounded,
                    iconColor: const Color(0xFF0068FF),
                    currentChoice: _selectedPaymentMethod,
                    onTap: () {
                      setSheetState(() => _selectedPaymentMethod = 'zalopay');
                      setState(() => _selectedPaymentMethod = 'zalopay');
                    },
                  ),
                  const SizedBox(height: 8),

                  // Option 5: Tiền mặt COD
                  _buildPaymentRadioTile(
                    theme: theme,
                    isDark: isDark,
                    keyName: 'cod',
                    title: 'Tiền mặt khi nhận đồ (COD)',
                    subTitle: 'Thanh toán cho Shipper tại sảnh tòa nhà',
                    icon: Icons.payments_rounded,
                    iconColor: AppColors.tertiary,
                    currentChoice: _selectedPaymentMethod,
                    onTap: () {
                      setSheetState(() => _selectedPaymentMethod = 'cod');
                      setState(() => _selectedPaymentMethod = 'cod');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Nút xác nhận phương thức
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMd,
                          ),
                        ),
                      ),
                      onPressed: () {
                        AppHaptics.selection();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Xác nhận phương thức',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentRadioTile({
    required LangFoodThemeExtension theme,
    required bool isDark,
    required String keyName,
    required String title,
    required String subTitle,
    required IconData icon,
    required Color iconColor,
    required String currentChoice,
    required VoidCallback onTap,
    String? badgeText,
  }) {
    final isSelected = currentChoice == keyName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : (isDark ? theme.surfaceContainerLow : const Color(0xFFF9F9FB)),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.borderSubtle,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : theme.textSecondary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.titleMd.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subTitle,
                    style: AppTypography.bodySm.copyWith(
                      color: theme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thực hiện đặt hàng an toàn (Order Submission Safety)
  Future<void> _submitOrder(double grandTotal) async {
    if (_isSubmittingOrder) return;

    AppHaptics.medium();
    setState(() => _isSubmittingOrder = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Hiển thị Dialog Loading đang xử lý thanh toán
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = ctx.langFoodTheme;
        return Dialog(
          backgroundColor: theme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Đang xử lý đơn hàng',
                  style: AppTypography.titleMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hệ thống đang kết nối với tài xế KTX và gửi yêu cầu chuẩn bị món...',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final customerName =
          authProvider.user?.fullName ??
          authProvider.user?.username ??
          'Sinh viên KTX';
      final phone = authProvider.user?.phoneNumber ?? '0987654321';

      final testOrder = OrderTestModel(
        customerName: customerName,
        deliveryAddress:
            '${_currentLocation.buildingName} (${_currentLocation.dropOffOptionLabel})',
        phone: phone,
        latitude: _currentLocation.position.latitude,
        longitude: _currentLocation.position.longitude,
        totalAmount: grandTotal,
        status: 'Ready',
      );

      // Gọi API OrderTestService an toàn giữ nguyên luồng hiện tại
      await OrderTestService().createOrderTest(testOrder);

      if (mounted) {
        Navigator.pop(context); // Tắt Dialog loading
      }

      // Làm sạch giỏ hàng sau khi đặt thành công
      cartProvider.clearCart(authProvider.user?.id);

      if (mounted) {
        _showSuccessDialogAndNavigate();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tắt Dialog loading
      }
      setState(() => _isSubmittingOrder = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi xử lý đơn hàng: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.errorApple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialogAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = ctx.langFoodTheme;
        return Dialog(
          backgroundColor: theme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.tertiary,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: const Text(
                    'Mã đơn: #LF-899',
                    style: TextStyle(
                      color: AppColors.tertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đặt đơn thành công!',
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tài xế sinh viên KTX đang trên đường nhận món và giao tận sảnh cho bạn.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Điều hướng sang màn hình theo dõi đơn hàng trực tiếp
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveTrackingScreen(
                            isShipper: false,
                            initialCustomerPos: _currentLocation.position,
                            initialAddress: _currentLocation.buildingName,
                            isLocationLocked: true,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Theo dõi hành trình đơn hàng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    final customerName =
        authProvider.user?.fullName ??
        authProvider.user?.username ??
        'Nguyễn Văn Minh';
    final customerPhone = authProvider.user?.phoneNumber ?? '0987 654 321';

    // Dữ liệu món ăn từ giỏ hàng
    final shopMap = cartProvider.itemsByShop;
    final int totalItemsCount = cartProvider.totalItemsCount;
    final int totalShopsCount = shopMap.keys.length;

    // Chi phí tính toán
    final double rawSubtotal = cartProvider.totalAmount > 0
        ? cartProvider.totalAmount
        : 48000.0;
    final double campusDeliveryFee = totalShopsCount >= 2 ? 15000.0 : 0.0;
    final double pairDiscount = (totalShopsCount >= 2) ? 10000.0 : 0.0;
    final double studentVoucherDiscount =
        (_isPairVoucherApplied && rawSubtotal >= 50000) ? 20000.0 : 0.0;
    final double doorDropOffFee = _currentLocation.extraFee;

    // Tổng thanh toán cuối cùng
    final double grandTotal =
        (rawSubtotal +
                campusDeliveryFee +
                doorDropOffFee -
                pairDiscount -
                studentVoucherDiscount)
            .clamp(0.0, double.infinity);
    final double totalSavings =
        pairDiscount +
        studentVoucherDiscount +
        (totalShopsCount >= 2 ? 0.0 : 15000.0);

    return Scaffold(
      backgroundColor: theme.canvas,
      appBar: AppBar(
        backgroundColor: isDark
            ? theme.card
            : Colors.white.withValues(alpha: 0.95),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: theme.textPrimary,
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Xác nhận đơn hàng',
          style: AppTypography.titleMd.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.marginMobile,
              AppTokens.spaceSm,
              AppTokens.marginMobile,
              140.0, // Chừa khoảng trống an toàn cho Sticky Payment Bar
            ),
            children: [
              // Banner thông báo Chế độ thử nghiệm an toàn (IB-06)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.amber.shade900,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chế độ thử nghiệm: Đơn hàng sẽ gửi qua hệ thống mô phỏng OrderTest.',
                        style: AppTypography.labelSm.copyWith(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spaceMd),

              // KHỐI 1: Thẻ địa chỉ nhận hàng KTX (Delivery Address Card)
              _buildDeliveryAddressCard(
                context,
                customerName: customerName,
                customerPhone: customerPhone,
              ),
              const SizedBox(height: AppTokens.spaceMd),

              // KHỐI 2: Tóm tắt danh sách món đã chọn (Order Items Recap)
              _buildOrderItemsRecapCard(
                context,
                shopMap: shopMap,
                cartProvider: cartProvider,
                totalShopsCount: totalShopsCount,
              ),
              const SizedBox(height: AppTokens.spaceMd),

              // KHỐI 3: Phương thức thanh toán (Payment Method Selector)
              _buildPaymentMethodCard(context),
              const SizedBox(height: AppTokens.spaceMd),

              // KHỐI 4: Vouchers sinh viên đã áp dụng
              _buildCampusVouchersCard(context),
              const SizedBox(height: AppTokens.spaceMd),

              // KHỐI 5: Chi tiết biểu phí & Tiết kiệm sinh viên (Pricing Breakdown)
              _buildPricingBreakdownCard(
                context,
                rawSubtotal: rawSubtotal,
                totalItemsCount: totalItemsCount,
                campusDeliveryFee: campusDeliveryFee,
                pairDiscount: pairDiscount,
                voucherDiscount: studentVoucherDiscount,
                doorDropOffFee: doorDropOffFee,
                grandTotal: grandTotal,
                totalSavings: totalSavings,
                totalShopsCount: totalShopsCount,
              ),
              const SizedBox(height: AppTokens.spaceMd),

              // KHỐI 6: Cam kết dịch vụ giao hàng KTX
              _buildCampusGuaranteesCard(context),
            ],
          ),

          // KHỐI 7: Thanh tác vụ ghim đáy (Sticky Bottom Action Bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildStickyBottomActionBar(
              context,
              grandTotal: grandTotal,
              totalSavings: totalSavings,
            ),
          ),
        ],
      ),
    );
  }

  // 1. Thẻ thông tin địa chỉ KTX
  Widget _buildDeliveryAddressCard(
    BuildContext context, {
    required String customerName,
    required String customerPhone,
  }) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
        boxShadow: isDark ? AppTokens.shadowLevel1Dark : AppTokens.shadowLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Nút Thay đổi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Điểm nhận hàng KTX',
                        style: AppTypography.titleMd.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _onChangeLocation,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    'Thay đổi',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tên tòa nhà và Badge xác thực
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _currentLocation.buildingName,
                style: AppTypography.titleMd.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Đã xác minh KTX',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _currentLocation.dropOffOptionLabel,
            style: AppTypography.bodySm.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$customerName • $customerPhone',
            style: AppTypography.bodySm.copyWith(color: theme.textSecondary),
          ),
          if (_currentLocation.shipperNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.surfaceContainerLow
                    : const Color(0xFFF3F3F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Ghi chú: "${_currentLocation.shipperNote}"',
                style: AppTypography.labelSm.copyWith(
                  color: theme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Time estimate pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Giao nhanh 20 - 25 phút • Hôm nay tại KTX B',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Thẻ tóm tắt các món trong đơn hàng
  Widget _buildOrderItemsRecapCard(
    BuildContext context, {
    required Map<int, List<dynamic>> shopMap,
    required CartProvider cartProvider,
    required int totalShopsCount,
  }) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
        boxShadow: isDark ? AppTokens.shadowLevel1Dark : AppTokens.shadowLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.layers_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        totalShopsCount >= 2
                            ? 'Đơn ghép KTX ĐHQG'
                            : 'Món ăn đã chọn',
                        style: AppTypography.titleMd.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalShopsCount >= 2)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                  child: Text(
                    '2 Quán • 1 Shipper',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Lặp qua các quán ăn trong giỏ
          ...shopMap.entries.map((entry) {
            final shopId = entry.key;
            final items = entry.value;
            final shopName = cartProvider.getShopName(shopId);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.surfaceContainerLow
                    : const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên quán
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Quán',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shopName,
                          style: AppTypography.titleMd.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Danh sách món của quán này
                  ...items.map((item) {
                    final hasOptions =
                        item.selectedOptionsJson != null &&
                        item.selectedOptionsJson!.trim().isNotEmpty;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.borderSubtle.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: AppTypography.labelSm.copyWith(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: AppTypography.bodySm.copyWith(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (hasOptions) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.selectedOptionsJson!,
                                    style: AppTypography.labelSm.copyWith(
                                      color: theme.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCurrency(item.totalPrice),
                            style: AppTypography.bodySm.copyWith(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 3. Thẻ phương thức thanh toán
  Widget _buildPaymentMethodCard(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    String methodTitle = 'Ví sinh viên LangFood Pay';
    String methodSub = 'Số dư: 150.000₫ • Hoàn 5% vào ví';
    IconData methodIcon = Icons.account_balance_wallet_rounded;
    Color iconColor = AppColors.primary;

    if (_selectedPaymentMethod == 'momo') {
      methodTitle = 'Ví MoMo KTX Express';
      methodSub = '1-chạm MoMo Sinh Viên';
      methodIcon = Icons.flash_on_rounded;
      iconColor = const Color(0xFFA50064);
    } else if (_selectedPaymentMethod == 'vietqr') {
      methodTitle = 'VietQR Pro / Chuyển khoản';
      methodSub = 'Quét mã QR ngân hàng 24/7 (0đ phí)';
      methodIcon = Icons.qr_code_2_rounded;
      iconColor = AppColors.secondary;
    } else if (_selectedPaymentMethod == 'zalopay') {
      methodTitle = 'Ví ZaloPay';
      methodSub = 'Thanh toán qua Zalo';
      methodIcon = Icons.account_balance_rounded;
      iconColor = const Color(0xFF0068FF);
    } else if (_selectedPaymentMethod == 'cod') {
      methodTitle = 'Tiền mặt khi nhận đồ (COD)';
      methodSub = 'Thanh toán cho Shipper tại sảnh tòa nhà';
      methodIcon = Icons.payments_rounded;
      iconColor = AppColors.tertiary;
    }

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
        boxShadow: isDark ? AppTokens.shadowLevel1Dark : AppTokens.shadowLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Phương thức thanh toán',
                  style: AppTypography.titleMd.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _openPaymentMethodBottomSheet,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Đổi',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Thẻ hiển thị phương thức đang được chọn
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.surfaceContainerLow
                  : const Color(0xFFF9F9FB),
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Icon(methodIcon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              methodTitle,
                              style: AppTypography.titleMd.copyWith(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedPaymentMethod == 'langfood') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '-5K',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        methodSub,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.tertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Thẻ voucher sinh viên
  Widget _buildCampusVouchersCard(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
        boxShadow: isDark ? AppTokens.shadowLevel1Dark : AppTokens.shadowLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sell_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voucher Làng Đại Học đã chọn',
                  style: AppTypography.titleMd.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_isPairVoucherApplied)
                Container(
                  constraints: const BoxConstraints(maxWidth: 230),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.surfaceContainerLow
                        : const Color(0xFFF3F3F5),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_activity_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'LANGFOODPAIR (-20.000₫)',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          AppHaptics.light();
                          setState(() => _isPairVoucherApplied = false);
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isFreeshipVoucherApplied)
                Container(
                  constraints: const BoxConstraints(maxWidth: 230),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.surfaceContainerLow
                        : const Color(0xFFF3F3F5),
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.electric_moped_rounded,
                        size: 14,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'FREESHIPKTX (Freeship)',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          AppHaptics.light();
                          setState(() => _isFreeshipVoucherApplied = false);
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Thẻ chi tiết thanh toán (Pricing Breakdown)
  Widget _buildPricingBreakdownCard(
    BuildContext context, {
    required double rawSubtotal,
    required int totalItemsCount,
    required double campusDeliveryFee,
    required double pairDiscount,
    required double voucherDiscount,
    required double doorDropOffFee,
    required double grandTotal,
    required double totalSavings,
    required int totalShopsCount,
  }) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
        boxShadow: isDark ? AppTokens.shadowLevel1Dark : AppTokens.shadowLevel1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết thanh toán',
            style: AppTypography.titleMd.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          _buildPriceRow(
            label: 'Tổng tiền món ($totalItemsCount món)',
            value: _formatCurrency(rawSubtotal),
            textColor: theme.textPrimary,
          ),
          const SizedBox(height: 8),

          _buildPriceRow(
            label: totalShopsCount >= 2
                ? 'Phí giao hàng KTX (Ghép 2 quán)'
                : 'Phí giao hàng KTX',
            value: campusDeliveryFee > 0
                ? _formatCurrency(campusDeliveryFee)
                : 'Freeship KTX',
            textColor: campusDeliveryFee > 0
                ? theme.textPrimary
                : AppColors.tertiary,
          ),
          if (doorDropOffFee > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: 'Phụ phí giao tận phòng (Lầu cao)',
              value: _formatCurrency(doorDropOffFee),
              textColor: AppColors.primary,
            ),
          ],
          if (pairDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: 'Giảm giá combo ghép quán KTX',
              value: '-${_formatCurrency(pairDiscount)}',
              textColor: AppColors.tertiary,
            ),
          ],
          if (voucherDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              label: 'Voucher sinh viên (LANGFOODPAIR)',
              value: '-${_formatCurrency(voucherDiscount)}',
              textColor: AppColors.primary,
            ),
          ],
          const SizedBox(height: 8),

          _buildPriceRow(
            label: 'Phí bao bì sinh viên',
            value: '0₫ (Trợ giá KTX)',
            textColor: AppColors.tertiary,
          ),
          const SizedBox(height: 12),

          Divider(height: 1, color: theme.borderSubtle),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tổng thanh toán',
                  style: AppTypography.titleMd.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _formatCurrency(grandTotal),
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          if (totalSavings > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    size: 16,
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Bạn đã tiết kiệm được ${_formatCurrency(totalSavings)} trong đơn này!',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  // 6. Cam kết KTX
  Widget _buildCampusGuaranteesCard(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      decoration: BoxDecoration(
        color: isDark ? theme.surfaceContainerLow : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tài xế sinh viên ĐHQG giao tận sảnh tòa nhà, gọi điện trước 2 phút khi chuẩn bị tới nơi.',
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.support_agent_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đổi trả hoặc hoàn tiền nhanh trong 5 phút nếu món ăn bị đổ vỡ hoặc sai yêu cầu.',
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Sticky Bottom Action Bar
  Widget _buildStickyBottomActionBar(
    BuildContext context, {
    required double grandTotal,
    required double totalSavings,
  }) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.surfaceContainerLow.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        boxShadow: AppTokens.shadowLevel3,
        border: Border(top: BorderSide(color: theme.borderSubtle, width: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTokens.marginMobile,
        10,
        AppTokens.marginMobile,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          return Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Text(
                            'Tổng thanh toán',
                            style: AppTypography.labelSm.copyWith(
                              color: theme.textSecondary,
                            ),
                          ),
                          if (totalSavings > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(Tiết kiệm ${_formatCurrency(totalSavings)})',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.tertiary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(grandTotal),
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isCompact ? 110 : 150,
                  maxWidth: 180,
                  maxHeight: 48,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  onPressed: _isSubmittingOrder
                      ? null
                      : () => _submitOrder(grandTotal),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đặt đơn ngay',
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
