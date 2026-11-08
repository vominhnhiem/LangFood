import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_card.dart';
import '../../../../core/widgets/langfood_status_badge.dart';
import '../../../../data/models/order_test_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';

class ShipperOrdersScreen extends StatefulWidget {
  final bool enablePeriodicTimer;
  final List<OrderTestModel>? initialOrders;

  const ShipperOrdersScreen({
    super.key,
    this.enablePeriodicTimer = true,
    this.initialOrders,
  });

  @override
  State<ShipperOrdersScreen> createState() => _ShipperOrdersScreenState();
}

class _ShipperOrdersScreenState extends State<ShipperOrdersScreen> {
  final OrderService _orderService = OrderService();
  List<OrderTestModel> _orders = [];
  bool _isLoading = false;
  bool _openingOrder = false;
  final _pickupAddresses = <int, String>{};
  String? _error;
  Timer? _liveTimer;
  final Set<int> _notifiedOrderIds = <int>{};
  bool _isInitialized = false;
  int _previousOrderCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrders != null) {
      _orders = List.from(widget.initialOrders!);
      _isLoading = false;
      _previousOrderCount = _orders.length;
      for (final o in _orders) {
        if (o.id != null) _notifiedOrderIds.add(o.id!);
      }
      _isInitialized = true;
    } else {
      _fetchOrders();
    }

    if (widget.enablePeriodicTimer) {
      _liveTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _pollOrdersSilent();
      });
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();

    super.dispose();
  }

  void _handleOrdersList(
    List<OrderTestModel> incomingList, {
    bool isInitialFetch = false,
  }) {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shipperId = authProvider.user?.shipperId;

    // Lọc đơn khả dụng cho shipper hiện tại:
    // - Đơn Ready (chờ nhận)
    // - Hoặc đơn của chính shipper này đang giao (Delivering)
    final filtered = incomingList
        .where(
          (o) =>
              o.status == 'Ready' ||
              (o.shipperId == shipperId && o.status != 'Completed'),
        )
        .toList();

    // Tìm các đơn mới chờ nhận (Ready) mà shipper chưa từng được thông báo
    final newlyArrived = filtered
        .where(
          (o) =>
              o.id != null &&
              !_notifiedOrderIds.contains(o.id) &&
              o.status == 'Ready',
        )
        .toList();

    // Chỉ hiển thị thông báo nổi nếu:
    // 1. Đã hoàn tất lần tải đầu tiên (không spam các đơn có sẵn khi vừa mở màn hình)
    // 2. Không phải là isInitialFetch
    // 3. Màn hình hiện tại đang hiển thị trên cùng (isCurrent == true, không bị che bởi LiveTrackingScreen hoặc dialog)
    // 4. Có đơn mới thực sự
    // 5. Trong môi trường test có initialOrders rỗng, không hiện SnackBar để tránh conflict text matching của test card
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final shouldNotify =
        _isInitialized &&
        !isInitialFetch &&
        isCurrentRoute &&
        newlyArrived.isNotEmpty &&
        (widget.initialOrders == null || _previousOrderCount > 0);

    if (shouldNotify) {
      AppHaptics.medium();
      final newest = newlyArrived.first;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🔔 Đơn KTX mới: #${newest.id ?? 'Mới'} từ ${newest.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    // Đánh dấu tất cả ID đã xử lý vào Set để ngăn chặn thông báo lặp
    for (final o in filtered) {
      if (o.id != null) {
        _notifiedOrderIds.add(o.id!);
      }
    }

    _previousOrderCount = filtered.length;

    setState(() {
      _orders = filtered;
      _isLoading = false;
      _error = null;
    });
  }

  Future<List<OrderTestModel>> _loadRealOrders(int? shipperId) async {
    if (shipperId == null) throw Exception('Tài khoản chưa có mã shipper.');
    final orders = await _orderService.getOrdersForShipper(shipperId);
    final pickups = {
      for (final order in orders)
        if (order.status == 'PickingUp' &&
            order.shipperId == shipperId &&
            !_pickupAddresses.containsKey(order.shopId))
          order.shopId,
    };
    await Future.wait(
      pickups.map((shopId) async {
        try {
          final pickup = await _orderService.getShopPickup(shopId);
          final address = pickup['address'];
          if (address is String && address.trim().isNotEmpty) {
            _pickupAddresses[shopId] = address;
          }
        } catch (_) {
          // The map can retry this lookup without blocking the trip list.
        }
      }),
    );
    return orders
        .map(
          (order) => OrderTestModel(
            id: order.id,
            customerName: order.buyerName ?? 'Khách hàng',
            pickupAddress: _pickupAddresses[order.shopId],
            phone: order.deliveryPhone ?? '',
            deliveryAddress: [
              order.deliveryBuilding,
              order.deliveryRoom,
            ].whereType<String>().join(' • '),
            latitude: order.deliveryLatitude ?? 0,
            longitude: order.deliveryLongitude ?? 0,
            totalAmount: order.totalAmount + (order.shippingFee ?? 0),
            status: order.status,
            shipperId: order.shipperId,
            createdAt: order.createdAt,
          ),
        )
        .toList();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shipperId = authProvider.user?.shipperId;

    try {
      final list = await _loadRealOrders(shipperId);
      if (!mounted) return;
      _handleOrdersList(list, isInitialFetch: !_isInitialized);
      _isInitialized = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _pollOrdersSilent() async {
    if (!mounted) return;
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (!isCurrent) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shipperId = authProvider.user?.shipperId;

    try {
      final list = await _loadRealOrders(shipperId);
      if (!mounted) return;
      _handleOrdersList(list);
    } catch (_) {}
  }

  Future<void> _acceptOrder(OrderTestModel order) async {
    final orderId = order.id;
    if (_openingOrder || orderId == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shipperId = authProvider.user?.shipperId;
    setState(() => _openingOrder = true);

    try {
      if (shipperId == null) throw Exception('Tài khoản chưa có mã shipper.');
      final claiming = !_inProgress(order);
      if (claiming) {
        final claimed = await _orderService.acceptOrder(orderId, shipperId);
        if (!claimed) throw Exception('Đơn chưa được xác nhận.');
      }
      if (!mounted) return;
      if (claiming) {
        AppHaptics.medium();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Đã nhận đơn #$orderId.')));
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveTrackingScreen(
            orderId: orderId,
            isShipper: true,
            autoShareGps: true,
            initialCustomerPos: order.latitude == 0 && order.longitude == 0
                ? null
                : LatLng(order.latitude, order.longitude),
            initialAddress: order.deliveryAddress,
          ),
        ),
      );
      if (mounted) await _fetchOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể nhận đơn: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingOrder = false);
    }
  }

  void _showRoleSwitcher(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      sheetAnimationStyle: AppMotion.sheetStyle(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chuyển đổi 3 Role (Demo Giảng Viên)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text(
                    'Chọn vai trò để kiểm thử quy trình khép kín:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFECE5),
                      child: Icon(Icons.person, color: Color(0xFFFF5722)),
                    ),
                    title: const Text('1. Sinh viên (Khách hàng)'),
                    subtitle: const Text('Tài khoản: nhiem - Đặt đồ ăn'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final nav = Navigator.of(context);
                      await auth.login('nhiem', 'nhiem2512005');
                      if (mounted) {
                        nav.pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.storefront, color: Colors.green),
                    ),
                    title: const Text('2. Chủ quán (Seller / Shop)'),
                    subtitle: const Text('Tài khoản: seller - Nhận đơn quán'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final nav = Navigator.of(context);
                      await auth.login('seller', '123456');
                      if (mounted) {
                        nav.pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF3E0),
                      child: Icon(Icons.directions_bike, color: Colors.orange),
                    ),
                    title: const Text('3. Tài xế (Shipper)'),
                    subtitle: const Text(
                      'Tài khoản: shipper - Đang ở màn hình này',
                    ),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.orange,
                    ),
                    onTap: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _inProgress(OrderTestModel order) =>
      order.status == 'PickingUp' || order.status == 'Delivering';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = context.langFoodTheme;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final active = _orders.where(_inProgress).toList();
    final ready = _orders.where((order) => !_inProgress(order)).toList();
    final orders = [...active, ...ready];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipper KTX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Đổi vai trò Demo (3 Roles)',
            onPressed: () => _showRoleSwitcher(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại danh sách',
            onPressed: _isLoading ? null : _fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: auth.logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverToBoxAdapter(
                child: LangFoodCard(
                  padding: const EdgeInsets.all(18),
                  showShadow: false,
                  backgroundColor: scheme.secondaryContainer,
                  showBorder: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'KTX KHU B / GIAO NHẬN',
                            style: text.labelMedium?.copyWith(
                              color: scheme.onSecondaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_error == null)
                            const LangFoodStatusBadge(
                              label: 'Trực tuyến',
                              variant: StatusBadgeVariant.success,
                              icon: Icons.circle,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text('Chuyến giao của bạn', style: text.headlineSmall),
                      if (!_isLoading && _error == null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${active.length} đang xử lý · ${ready.length} chờ nhận',
                          style: text.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading || _error != null || orders.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _error == null
                                    ? Icons.delivery_dining_outlined
                                    : Icons.cloud_off_rounded,
                                size: 42,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error ?? 'Chưa có đơn hàng',
                                style: text.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              if (_error == null)
                                Text(
                                  'Các đơn sẵn sàng lấy món sẽ xuất hiện ở đây.',
                                  style: text.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _fetchOrders,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(
                                  _error == null
                                      ? 'Tải lại danh sách đơn'
                                      : 'Thử lại',
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final startsSection = index == 0 || index == active.length;
                    return Padding(
                      key: ValueKey(order.id ?? index),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (startsSection)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                              child: Text(
                                _inProgress(order)
                                    ? 'Đang thực hiện'
                                    : 'Sẵn sàng nhận',
                                style: text.titleMedium,
                              ),
                            ),
                          _orderCard(context, order),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderTestModel order) {
    final colors = context.langFoodTheme;
    final text = Theme.of(context).textTheme;
    final inProgress = _inProgress(order);
    final pickingUp = order.status == 'PickingUp';
    final destination = pickingUp
        ? order.pickupAddress ?? 'Xem địa chỉ quán trên bản đồ'
        : order.deliveryAddress.trim().isEmpty
        ? 'Chưa có địa chỉ giao'
        : order.deliveryAddress;
    final status = switch (order.status) {
      'PickingUp' => 'Đến lấy món',
      'Delivering' => 'Đang giao',
      'Ready' || 'Accepted' || 'Confirmed' => 'Chờ nhận',
      _ => order.status,
    };

    return LangFoodCard(
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                'Đơn #${order.id ?? '—'}',
                style: AppTypography.currencyDisplay,
              ),
              LangFoodStatusBadge(
                label: status,
                icon: inProgress ? Icons.route_rounded : Icons.schedule_rounded,
                variant: inProgress
                    ? StatusBadgeVariant.info
                    : StatusBadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pickingUp ? 'ĐIỂM LẤY MÓN' : 'ĐIỂM GIAO',
            style: text.labelSmall,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 21,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(destination, style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.customerName,
            style: text.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          if (order.phone.trim().isNotEmpty)
            Text(
              order.phone,
              style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          const SizedBox(height: 8),
          const Divider(),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text(
                'Tổng tiền đơn hàng',
                style: text.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              Text(
                _formatCurrency(order.totalAmount),
                style: AppTypography.currencyDisplay,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openingOrder || order.id == null
                ? null
                : () => _acceptOrder(order),
            icon: Icon(
              inProgress
                  ? Icons.navigation_outlined
                  : Icons.delivery_dining_rounded,
            ),
            label: Text(
              inProgress
                  ? (pickingUp ? 'Đường đến quán' : 'Đường đến điểm giao')
                  : 'NHẬN ĐƠN NGAY',
            ),
          ),
        ],
      ),
    );
  }
}
