import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';
import '../../../tracking/presentation/screens/location_picker_screen.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../tracking/presentation/screens/realtime_order_tracking_screen.dart';

enum LF07CheckoutState {
  normal, // Chuẩn (2 Quán ghép)
  processing, // Đang xử lý
  success, // Thành công (Success Modal)
}

enum PaymentMethodType {
  langfoodPay, // Ví sinh viên LangFood Pay
  momo, // MoMo Express
  vietQr, // VietQR Napas 24/7
  zaloPay, // ZaloPay
  cod, // Tiền mặt tại sảnh KTX (COD)
}

enum _LF07HapticType {
  light,
  medium,
  selection,
}

class CheckoutScreen extends StatefulWidget {
  final String? deliveryAddress;

  const CheckoutScreen({
    super.key,
    this.deliveryAddress,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  // Inspector & UI state
  LF07CheckoutState _checkoutState = LF07CheckoutState.normal;
  bool _isDarkMode = false;
  bool _showHigOverlay = false;

  // Delivery info
  late String _currentAddress;
  String _customerName = 'Nguyễn Văn Minh';
  String _customerPhone = '0987 654 321';
  String _deliveryTime = '⚡ 20 - 25 phút (12:15 - 12:30 hôm nay)';

  // Payment Method
  PaymentMethodType _selectedPayment = PaymentMethodType.langfoodPay;
  double _walletBalance = 150000;

  // Vouchers
  final List<Map<String, dynamic>> _appliedVouchers = [
    {
      'code': 'LANGFOODPAIR',
      'title': 'Giảm 20.000₫ đơn ghép 2 quán',
      'discount': 20000,
    },
    {
      'code': 'FREESHIPKTX',
      'title': 'Freeship sảnh KTX Khu B',
      'discount': 15000,
    },
  ];

  // Financial Breakdown - lấy trực tiếp từ giỏ hàng thực tế
  double get _itemSubtotal {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return cart.items.isNotEmpty ? cart.totalAmount : 35000;
  }
  final double _multiShopShippingFee = 10000; // Phí ship KTX
  final double _comboShopDiscount = 0;
  final double _voucherDiscount = 0;
  final double _packagingFee = 0;

  double get _finalTotal => _itemSubtotal + _multiShopShippingFee;
  double get _totalSaved => 0;

  final TextEditingController _noteShop1Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentAddress = widget.deliveryAddress ??
        'Tòa BA2 - KTX Khu B ĐHQG • Sảnh Tầng G (Chân thang máy)';
  }

  @override
  void dispose() {
    _noteShop1Controller.dispose();
    super.dispose();
  }

  void _triggerHaptic([_LF07HapticType type = _LF07HapticType.light]) {
    try {
      if (type == _LF07HapticType.selection) {
        HapticFeedback.selectionClick();
      } else if (type == _LF07HapticType.medium) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  Future<void> _handlePlaceOrder() async {
    _triggerHaptic(_LF07HapticType.medium);
    setState(() => _checkoutState = LF07CheckoutState.processing);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Lấy shopId từ giỏ hàng (nếu có quán, hoặc mặc định 1)
    int targetShopId = 1;
    if (cartProvider.itemsByShop.isNotEmpty) {
      targetShopId = cartProvider.itemsByShop.keys.first;
    }

    final orderItems = cartProvider.items.map((cartItem) {
      return OrderItemModel(
        productId: cartItem.product.id > 0 ? cartItem.product.id : 1,
        productName: cartItem.product.name,
        quantity: cartItem.quantity > 0 ? cartItem.quantity : 1,
        unitPrice: cartItem.effectiveUnitPrice,
        note: cartItem.note,
      );
    }).toList();

    final newOrder = OrderModel(
      buyerId: (authProvider.user?.id != null && authProvider.user!.id.isNotEmpty)
          ? authProvider.user!.id
          : '2A16828F-7451-410C-9174-1AE06CB01186',
      buyerName: authProvider.user?.fullName ?? authProvider.user?.username ?? 'Nguyễn Văn Sinh Viên',
      shopId: targetShopId > 0 ? targetShopId : 1,
      status: 'Pending',
      totalAmount: cartProvider.totalAmount > 0 ? cartProvider.totalAmount : 35000.0,
      shippingFee: 10000.0,
      deliveryBuilding: widget.deliveryAddress ?? authProvider.user?.ktxRoom ?? 'Tòa B4 - P302 (KTX Khu B)',
      deliveryPhone: authProvider.user?.phoneNumber ?? '0901234567',
      paymentMethod: _selectedPayment == PaymentMethodType.cod ? 0 : 1,
      orderItems: orderItems,
    );

    try {
      final created = await OrderService().createOrder(newOrder);
      if (!mounted) return;

      cartProvider.clearCart(authProvider.user?.id);

      setState(() => _checkoutState = LF07CheckoutState.success);
      _showSuccessModal(created);
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkoutState = LF07CheckoutState.normal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo đơn hàng: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessModal([OrderModel? created]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final themeText = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final orderId = created?.id ?? 1;
        return AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Text(
                'Đặt đơn thành công! 🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: themeText),
              ),
              const SizedBox(height: 6),
              Text(
                'Mã đơn hàng: #LF-$orderId\nĐã gửi yêu cầu món đến quán ăn',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.orange,
                      radius: 20,
                      child: Icon(Icons.storefront_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quán Cơm Tấm Đêm KTX',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: themeText),
                          ),
                          const Text(
                            'Trạng thái: Đang chờ quán nhận đơn...',
                            style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RealtimeOrderTrackingScreen(
                          orderId: orderId,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'THEO DÕI TIẾN TRÌNH ĐƠN HÀNG',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Về trang chủ khám phá', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodSheet() {
    _triggerHaptic(_LF07HapticType.selection);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final themeBg = _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
        final themeText = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
        final themeBorder = _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          decoration: BoxDecoration(
            color: themeBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chọn phương thức thanh toán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: themeText),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ưu tiên ví sinh viên LangFood Pay để được hoàn/giảm ngay 5.000₫',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              _buildPaymentOptionTile(
                type: PaymentMethodType.langfoodPay,
                title: 'Ví sinh viên LangFood Pay',
                sub: 'Số dư: 150.000₫ • Giảm ngay 5.000₫',
                badge: 'Khuyên dùng 🔥',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.primary,
                themeText: themeText,
                themeBorder: themeBorder,
                onTap: () {
                  setState(() => _selectedPayment = PaymentMethodType.langfoodPay);
                  Navigator.pop(ctx);
                },
              ),

              _buildPaymentOptionTile(
                type: PaymentMethodType.momo,
                title: 'Ví điện tử MoMo Express',
                sub: 'Liên kết sinh viên 1-chạm không cần OTP',
                badge: null,
                icon: Icons.smartphone_rounded,
                iconColor: const Color(0xFFA50064),
                themeText: themeText,
                themeBorder: themeBorder,
                onTap: () {
                  setState(() => _selectedPayment = PaymentMethodType.momo);
                  Navigator.pop(ctx);
                },
              ),

              _buildPaymentOptionTile(
                type: PaymentMethodType.vietQr,
                title: 'VietQR Napas 24/7',
                sub: 'Chuyển khoản qua mã QR mọi ngân hàng',
                badge: 'Tự động duyệt',
                icon: Icons.qr_code_scanner_rounded,
                iconColor: const Color(0xFF0284C7),
                themeText: themeText,
                themeBorder: themeBorder,
                onTap: () {
                  setState(() => _selectedPayment = PaymentMethodType.vietQr);
                  Navigator.pop(ctx);
                },
              ),

              _buildPaymentOptionTile(
                type: PaymentMethodType.zaloPay,
                title: 'Ví ZaloPay',
                sub: 'Hoàn tiền 10% cho tân sinh viên KTX',
                badge: null,
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF0068FF),
                themeText: themeText,
                themeBorder: themeBorder,
                onTap: () {
                  setState(() => _selectedPayment = PaymentMethodType.zaloPay);
                  Navigator.pop(ctx);
                },
              ),

              _buildPaymentOptionTile(
                type: PaymentMethodType.cod,
                title: 'Tiền mặt tại sảnh KTX (COD)',
                sub: 'Trả tiền trực tiếp khi shipper đến chân thang máy',
                badge: null,
                icon: Icons.payments_rounded,
                iconColor: Colors.green,
                themeText: themeText,
                themeBorder: themeBorder,
                onTap: () {
                  setState(() => _selectedPayment = PaymentMethodType.cod);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOptionTile({
    required PaymentMethodType type,
    required String title,
    required String sub,
    required String? badge,
    required IconData icon,
    required Color iconColor,
    required Color themeText,
    required Color themeBorder,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedPayment == type;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : themeBorder,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
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
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: themeText,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = _isDarkMode ? const Color(0xFF121214) : const Color(0xFFF8F9FA);
    final themeCard = _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final themeTextPrimary = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final themeTextSecondary = _isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF64748B);
    final themeBorder = _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: themeBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Inspector & Navigation AppBar
            _buildInspectorBar(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
            _buildAppBar(themeCard, themeTextPrimary, themeBorder),

            // 2. Scrollable Checkout Body
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // CARD 1: Delivery Address KTX Card (Integrated from LF-06)
                  _buildDeliveryAddressCard(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
                  const SizedBox(height: 14),

                  // CARD 2: Multi-Shop Order Recap Badge & Grouped Dishes
                  _buildMultiShopRecapCard(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
                  const SizedBox(height: 14),

                  // CARD 3: Payment Method & Student Wallet
                  _buildPaymentMethodCard(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
                  const SizedBox(height: 14),

                  // CARD 4: Applied Vouchers Card
                  _buildVouchersCard(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
                  const SizedBox(height: 14),

                  // CARD 5: Cost Breakdown & Student Savings Banner
                  _buildCostBreakdownCard(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
                ],
              ),
            ),
          ],
        ),
      ),

      // 3. Sticky Bottom Action Bar
      bottomSheet: _buildStickyBottomActionBar(themeCard, themeTextPrimary, themeBorder),
    );
  }

  // ================= 1. APP BAR & INSPECTOR =================
  Widget _buildInspectorBar(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: _isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFF0F172A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.credit_card_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              'LF-07 Checkout:',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),

            // State: Normal
            _buildStateChip(LF07CheckoutState.normal, 'Chuẩn (2 Quán)', Icons.check_circle_rounded, const Color(0xFF10B981)),
            const SizedBox(width: 6),

            // State: Processing
            _buildStateChip(LF07CheckoutState.processing, 'Đang xử lý', Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
            const SizedBox(width: 6),

            // State: Success Modal
            InkWell(
              onTap: _showSuccessModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Xem Success Modal', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Light / Dark mode
            InkWell(
              onTap: () {
                _triggerHaptic(_LF07HapticType.selection);
                setState(() => _isDarkMode = !_isDarkMode);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.amber.withOpacity(0.2) : Colors.indigo.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      size: 13,
                      color: _isDarkMode ? Colors.amber : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isDarkMode ? 'Light' : 'Dark',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.amber : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateChip(LF07CheckoutState state, String label, IconData icon, Color color) {
    final isSelected = _checkoutState == state;
    return InkWell(
      onTap: () {
        _triggerHaptic(_LF07HapticType.selection);
        setState(() => _checkoutState = state);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(Color card, Color textPrimary, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: card,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thanh toán & Xác nhận',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const Text(
                  'LF-07 • Kiểm tra đơn hàng trước khi gửi bếp KTX',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: Colors.green),
                SizedBox(width: 2),
                Text('20-25p', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD 1: DELIVERY ADDRESS KTX =================
  Widget _buildDeliveryAddressCard(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'ĐỊA CHỈ NHẬN HÀNG KTX',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: textSecondary,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            '⚡ KTX',
                            style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Provider.of<AuthProvider>(context, listen: false).user?.fullName ?? _customerName} • ${Provider.of<AuthProvider>(context, listen: false).user?.phoneNumber ?? _customerPhone}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Shortcut "Thay đổi" -> Open LF-06 Campus Map
              TextButton(
                onPressed: () async {
                  _triggerHaptic(_LF07HapticType.selection);
                  final newAddr = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                  );
                  if (newAddr != null && mounted) {
                    setState(() => _currentAddress = newAddr);
                  }
                },
                child: const Text(
                  'Thay đổi',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.apartment_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentAddress,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Giao dự kiến: $_deliveryTime',
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  // ================= CARD 2: REAL CART ORDER RECAP =================
  Widget _buildMultiShopRecapCard(Color card, Color textPrimary, Color textSecondary, Color border) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.electric_moped_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đơn hàng Làng Food • Giao tận phòng KTX',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Text(
                  'Freeship sảnh',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Danh sách món ăn THỰC TẾ lấy từ CartProvider
          if (cartProvider.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Giỏ hàng đang trống! Vui lòng chọn món ăn từ thực đơn.',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...cartProvider.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.product.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 46,
                          height: 46,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity}x ${item.product.name}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                          ),
                          if (item.selectedOptionsSummary.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.selectedOptionsSummary,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            item.product.shopName,
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCurrency(item.totalPrice.toInt()),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 6),
          TextField(
            controller: _noteShop1Controller,
            style: TextStyle(fontSize: 12, color: textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Ghi chú cho quán (VD: ít cay, nhiều đá, giao lên phòng...)',
              hintStyle: TextStyle(fontSize: 11, color: textSecondary),
              prefixIcon: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
              filled: true,
              fillColor: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD 3: PAYMENT METHOD =================
  Widget _buildPaymentMethodCard(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PHƯƠNG THỨC THANH TOÁN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              InkWell(
                onTap: _showPaymentMethodSheet,
                child: const Text(
                  'Đổi phương thức >',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _showPaymentMethodSheet,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Ví sinh viên LangFood Pay',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '-5.000₫',
                                style: TextStyle(fontSize: 9.5, color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Số dư: ${_formatCurrency(_walletBalance)} (Đủ thanh toán)',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD 4: VOUCHERS =================
  Widget _buildVouchersCard(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VOUCHER SINH VIÊN KTX',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const Text(
                'Đã áp dụng 2 mã',
                style: TextStyle(fontSize: 11.5, color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._appliedVouchers.map((v) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_rounded, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v['code'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                        Text(v['title'] as String, style: TextStyle(fontSize: 10.5, color: Colors.green.shade800)),
                      ],
                    ),
                  ),
                  Text('-${_formatCurrency(v['discount'] as int)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= CARD 5: COST BREAKDOWN =================
  Widget _buildCostBreakdownCard(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHI TIẾT THANH TOÁN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),

          _buildCostRow('Tổng tiền món (4 món)', _formatCurrency(_itemSubtotal), textPrimary, textSecondary),
          _buildCostRow('Phí giao hàng ghép 2 quán', _formatCurrency(_multiShopShippingFee), textPrimary, textSecondary),
          _buildCostRow('Giảm combo ghép quán', '-${_formatCurrency(_comboShopDiscount)}', Colors.green, textSecondary),
          _buildCostRow('Voucher sinh viên KTX', '-${_formatCurrency(_voucherDiscount)}', Colors.green, textSecondary),
          _buildCostRow('Phí bao bì (Trợ giá thi cử)', '0₫ (Miễn phí)', Colors.green, textSecondary),

          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng thanh toán:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
              Text(
                _formatCurrency(_finalTotal),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Savings Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration_rounded, color: Colors.orange, size: 16),
                const SizedBox(width: 6),
                Text(
                  '🎉 Bạn đã tiết kiệm được ${_formatCurrency(_totalSaved)} trong đơn này!',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.brown.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String title, String amount, Color amountColor, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12.5, color: textSecondary)),
          Text(amount, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: amountColor)),
        ],
      ),
    );
  }

  // ================= STICKY BOTTOM ACTION BAR =================
  Widget _buildStickyBottomActionBar(Color card, Color textPrimary, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: card,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    _formatCurrency(_finalTotal),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                  const Text('Đã áp dụng 2 voucher KTX', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _checkoutState == LF07CheckoutState.processing ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _checkoutState == LF07CheckoutState.processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Đặt đơn ngay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
