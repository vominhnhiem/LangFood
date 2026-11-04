import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../../../config/config_url.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/display_format.dart';
import '../../../../data/models/checkout_selection.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../orders/presentation/screens/my_orders_screen.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';
import '../../../tracking/presentation/screens/location_picker_screen.dart';

/// LF-07: address, grouped recap, payment sheet and a safe-area checkout bar.
class CheckoutScreen extends StatefulWidget {
  final CampusDeliveryLocation deliveryLocation;
  final TileProvider? tileProvider;
  final CheckoutSelection? selection;
  final OrderService? service;
  const CheckoutScreen({
    super.key,
    required this.deliveryLocation,
    this.tileProvider,
    this.selection,
    this.service,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late CampusDeliveryLocation _location;
  late CheckoutSelection _selection;
  late final OrderService _service = widget.service ?? OrderService();
  String? _buyerId;
  late final double _baseFee;
  final Map<int, OrderModel> _created = {};
  bool _submitting = false;
  bool _finished = false;
  String? _error;
  bool _ambiguousFailure = false;
  bool _configurationError = false;

  @override
  void initState() {
    super.initState();
    _location = widget.deliveryLocation;
    _selection =
        widget.selection ??
        CheckoutSelection(context.read<CartProvider>().items);
    _buyerId = context.read<AuthProvider>().user?.id;
    try {
      _baseFee = ConfigUrl.shippingFee;
    } catch (_) {
      _baseFee = 10000.0;
    }
  }

  double get _feePerShop => _baseFee + _location.extraFee;
  double get _total =>
      _selection.subtotal + _feePerShop * _selection.byShop.length;

  Future<void> _changeLocation() async {
    final updated = await Navigator.push<CampusDeliveryLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _location,
          returnResult: true,
          tileProvider: widget.tileProvider,
        ),
      ),
    );
    if (updated != null && mounted) setState(() => _location = updated);
  }

  void _paymentSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.langFoodTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Phương thức thanh toán',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const ListTile(
                leading: Icon(Icons.check_circle, color: AppColors.primary),
                title: Text('Tiền mặt khi nhận đồ (COD)'),
                subtitle: Text('Thanh toán khi nhận món'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Xác nhận phương thức'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _retrySubmit() {
    setState(() {
      _ambiguousFailure = false;
      _error = null;
    });
    _submit();
  }

  Future<void> _submit() async {
    if (_submitting || _finished || _ambiguousFailure || _configurationError) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final currentBuyerId = _buyerId ?? auth.user?.id;
    if (currentBuyerId == null || auth.user?.id != currentBuyerId) {
      setState(
        () =>
            _error = 'Phiên đăng nhập đã thay đổi. Vui lòng quay lại giỏ hàng.',
      );
      return;
    }
    _buyerId = currentBuyerId;
    if (!_selection.isValid) return;
    final phone = auth.user?.phoneNumber?.trim() ?? '';
    if (phone.isEmpty) {
      setState(
        () => _error =
            'Vui lòng bổ sung số điện thoại trong hồ sơ trước khi đặt món.',
      );
      return;
    }
    if (!_location.position.latitude.isFinite ||
        !_location.position.longitude.isFinite ||
        _location.buildingName.trim().isEmpty) {
      return;
    }
    final cart = context.read<CartProvider>();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      for (final group in _selection.byShop.entries) {
        if (_created.containsKey(group.key)) continue;
        final subtotal = group.value.fold(
          0.0,
          (sum, item) => sum + item.totalPrice,
        );
        final created = await _service.createOrder(
          OrderModel(
            buyerId: currentBuyerId,
            buyerName: auth.user?.fullName ?? auth.user?.username,
            shopId: group.key,
            totalAmount: subtotal,
            shippingFee: _feePerShop,
            paymentMethod: 0,
            deliveryBuilding: _location.buildingName,
            deliveryRoom: [
              _location.dropOffOptionLabel,
              if (_location.shipperNote.isNotEmpty)
                'Ghi chú giao hàng: ${_location.shipperNote}',
            ].join(' • '),
            deliveryPhone: phone,
            deliveryLatitude: _location.position.latitude,
            deliveryLongitude: _location.position.longitude,
            orderItems: group.value
                .map(
                  (item) => OrderItemModel(
                    productId: item.product.id,
                    productName: item.product.name,
                    quantity: item.quantity,
                    unitPrice: item.effectiveUnitPrice,
                    note: [
                      if (item.note?.isNotEmpty == true) item.note!,
                      if (_selection.shopNotes[group.key]?.isNotEmpty == true)
                        'Ghi chú quán: ${_selection.shopNotes[group.key]}',
                    ].join(' • '),
                    optionsSummary: item.selectedOptionsSummary,
                    optionsPrice: (item.effectiveUnitPrice - item.product.price)
                        .clamp(0.0, double.infinity),
                  ),
                )
                .toList(),
          ),
        );
        if (created?.id == null || created!.id! <= 0) {
          throw const OrderSubmissionUncertain(
            'Máy chủ chưa trả mã đơn hợp lệ.',
          );
        }
        _created[group.key] = created;
        cart.removePurchased(group.value, currentBuyerId);
      }
      if (!mounted) return;
      setState(() => _finished = true);
      _successDialog();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ambiguousFailure = error is OrderSubmissionUncertain;
        _error =
            '${_created.isNotEmpty ? 'Đã tạo ${_created.length} đơn. ' : ''}'
            '${error.toString().replaceFirst('Exception: ', '')}'
            '${_ambiguousFailure ? ' Hãy kiểm tra Đơn hàng trước khi đặt lại để tránh trùng đơn.' : ''}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error!),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Kiểm tra',
            textColor: Colors.white,
            onPressed: _openOrders,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _openOrders() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
    (route) => route.isFirst,
  );

  void _successDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.check_circle,
          size: 48,
          color: AppColors.tertiary,
        ),
        title: const Text('Đặt đơn thành công!'),
        content: Text(
          '${_created.values.map((order) => '#LF-${order.id}').join(', ')}\n'
          'Đơn hàng đang chờ quán xác nhận. Thanh toán tiền mặt khi nhận món.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (_created.length > 1) {
                  _openOrders();
                  return;
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LiveTrackingScreen(
                      orderId: _created.values.single.id!,
                      initialCustomerPos: _location.position,
                      initialAddress: _location.buildingName,
                    ),
                  ),
                  (route) => route.isFirst,
                );
              },
              child: Text(
                _created.length > 1 ? 'Xem các đơn hàng' : 'Theo dõi đơn hàng',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() => _card(
    title: 'Chưa hoàn tất đặt đơn',
    icon: Icons.info_outline,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_error!, style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: _openOrders,
              icon: const Icon(Icons.receipt_long),
              label: const Text('Kiểm tra Đơn hàng'),
            ),
            FilledButton.tonalIcon(
              onPressed: _submitting ? null : _retrySubmit,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại đặt đơn'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    final theme = context.langFoodTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.borderSubtle, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _amount(String label, double value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(
          money(value),
          style: TextStyle(
            fontWeight: strong ? FontWeight.bold : FontWeight.normal,
            color: strong ? AppColors.primary : null,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final user = context.watch<AuthProvider>().user;
    final valid = _selection.isValid;
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: theme.canvas,
        appBar: AppBar(
          title: const Text('Xác nhận đơn hàng'),
          centerTitle: true,
          leading: BackButton(
            onPressed: _submitting ? null : () => Navigator.maybePop(context),
          ),
        ),
        body: !valid
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text('Chưa có món hợp lệ để thanh toán.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: const Text('Quay lại giỏ hàng'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) _errorCard(),
                  if (_selection.byShop.length > 1)
                    _card(
                      title:
                          '${_selection.byShop.length} quán • ${_selection.byShop.length} đơn riêng',
                      icon: Icons.storefront,
                      child: const Text(
                        'Mỗi quán tạo một đơn và tính phí giao riêng. Bạn có thể theo dõi từng đơn trong Đơn hàng.',
                      ),
                    ),
                  _card(
                    title: 'Điểm nhận hàng KTX',
                    icon: Icons.location_on,
                    action: TextButton(
                      onPressed: _submitting || _created.isNotEmpty
                          ? null
                          : _changeLocation,
                      child: const Text('Thay đổi'),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _location.buildingName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(_location.dropOffOptionLabel),
                        const SizedBox(height: 6),
                        Text(
                          '${user?.fullName ?? user?.username ?? ''} • ${user?.phoneNumber ?? 'Chưa có số điện thoại'}',
                        ),
                        if (_location.shipperNote.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Ghi chú: ${_location.shipperNote}'),
                          ),
                      ],
                    ),
                  ),
                  _card(
                    title: 'Món ăn đã chọn',
                    icon: Icons.restaurant,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final group in _selection.byShop.entries) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  group.value.first.product.shopName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_created.containsKey(group.key))
                                Text(
                                  'Đã tạo #${_created[group.key]!.id}',
                                  style: const TextStyle(
                                    color: AppColors.tertiary,
                                  ),
                                ),
                            ],
                          ),
                          for (final item in group.value)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item.quantity}x'),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name),
                                        if (item
                                            .selectedOptionsSummary
                                            .isNotEmpty)
                                          Text(
                                            item.selectedOptionsSummary,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.textSecondary,
                                            ),
                                          ),
                                        if (item.note?.isNotEmpty == true)
                                          Text('Ghi chú: ${item.note}'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(money(item.totalPrice)),
                                ],
                              ),
                            ),
                          if (_selection.shopNotes[group.key]?.isNotEmpty ==
                              true)
                            Text(
                              'Ghi chú quán: ${_selection.shopNotes[group.key]}',
                            ),
                          if (_selection.byShop.length > 1) const Divider(),
                        ],
                      ],
                    ),
                  ),
                  _card(
                    title: 'Phương thức thanh toán',
                    icon: Icons.payments,
                    action: TextButton(
                      onPressed: _submitting ? null : _paymentSheet,
                      child: const Text('Đổi'),
                    ),
                    child: const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.payments_outlined,
                        color: AppColors.tertiary,
                      ),
                      title: Text('Tiền mặt khi nhận đồ (COD)'),
                      subtitle: Text('Thanh toán khi nhận món'),
                    ),
                  ),
                  _card(
                    title: 'Chi tiết thanh toán',
                    icon: Icons.receipt_long,
                    child: Column(
                      children: [
                        _amount(
                          'Tiền món (${_selection.quantity} món)',
                          _selection.subtotal,
                        ),
                        _amount(
                          'Phí giao hàng (${_selection.byShop.length} đơn)',
                          _baseFee * _selection.byShop.length,
                        ),
                        if (_location.extraFee > 0)
                          _amount(
                            'Giao tận cửa phòng',
                            _location.extraFee * _selection.byShop.length,
                          ),
                        const Divider(),
                        _amount('Tổng thanh toán', _total, strong: true),
                      ],
                    ),
                  ),
                  if (_error != null) _errorCard(),
                  const SizedBox(height: 8),
                ],
              ),
        bottomNavigationBar: !valid
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: theme.card,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng thanh toán',
                              style: TextStyle(fontSize: 12),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                money(_total),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FilledButton(
                          onPressed:
                              _submitting ||
                                  _finished ||
                                  (_ambiguousFailure && _created.isEmpty) ||
                                  _configurationError
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _finished
                                      ? 'Đã đặt đơn'
                                      : _created.isEmpty
                                      ? 'Đặt đơn ngay'
                                      : 'Đặt các đơn còn lại',
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
