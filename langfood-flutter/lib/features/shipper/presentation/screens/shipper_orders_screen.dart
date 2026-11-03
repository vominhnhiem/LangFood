import '../../../../core/widgets/account_menu.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/order_model.dart';
import '../../../../data/services/location_service.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';

class ShipperOrdersScreen extends StatefulWidget {
  const ShipperOrdersScreen({super.key});
  @override
  State<ShipperOrdersScreen> createState() => _ShipperOrdersScreenState();
}

class _ShipperOrdersScreenState extends State<ShipperOrdersScreen>
    with WidgetsBindingObserver {
  final _service = OrderService();
  List<OrderModel> _orders = [];
  StreamSubscription<Position>? _positions;
  Timer? _refreshTimer;
  bool _loading = true;
  bool _refreshing = false;
  bool _startingGps = false;
  bool _sharing = false;
  bool _sharingWanted = false;
  bool _foreground = true;
  bool _sending = false;
  String? _error;
  String? _gpsError;
  DateTime? _lastSent;
  int? _busyOrder;

  int? get _shipperId => context.read<AuthProvider>().user?.shipperId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _positions?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed && _sharingWanted) {
      _startGps();
    } else if (state != AppLifecycleState.resumed) {
      _stopGps(resetWanted: false);
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final shipperId = _shipperId;
    if (shipperId == null) {
      setState(() {
        _loading = false;
        _error = 'Tài khoản chưa được gán hồ sơ shipper.';
      });
      return;
    }
    _refreshing = true;
    try {
      final orders = await _service.getOrdersForShipper(shipperId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
        _loading = false;
      });
      if (!_orders.any((o) => o.status == 'Delivering')) await _stopGps();
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _startGps() async {
    if (!_foreground ||
        _startingGps ||
        _sharing ||
        !_orders.any((o) => o.status == 'Delivering'))
      return;
    _sharingWanted = true;
    setState(() {
      _startingGps = true;
      _gpsError = null;
    });
    try {
      final first = await LocationService.current();
      if (!mounted || !_sharingWanted || !_foreground) return;
      _positions =
          Geolocator.getPositionStream(
            locationSettings: LocationService.settings,
          ).listen(
            (position) => _sendPosition(position),
            onError: (Object error) {
              if (mounted) {
                _stopGps();
                setState(() => _gpsError = 'Không nhận được GPS: $error');
              }
            },
          );
      setState(() => _sharing = true);
      await _sendPosition(first);
    } catch (e) {
      if (mounted) {
        await _stopGps();
        if (mounted)
          setState(
            () => _gpsError = e.toString().replaceFirst('Exception: ', ''),
          );
      }
    } finally {
      if (mounted) setState(() => _startingGps = false);
    }
  }

  Future<void> _stopGps({bool resetWanted = true}) async {
    if (resetWanted) _sharingWanted = false;
    final subscription = _positions;
    _positions = null;
    if (mounted) setState(() => _sharing = false);
    await subscription?.cancel();
  }

  Future<void> _sendPosition(Position position) async {
    if (_sending || !mounted || !_sharingWanted || !_foreground) return;
    if (!position.latitude.isFinite || !position.longitude.isFinite) return;
    final shipperId = _shipperId;
    if (shipperId == null) return;
    final activeOrders = _orders
        .where((o) => o.status == 'Delivering' && o.id != null)
        .toList();
    if (activeOrders.isEmpty) return;
    _sending = true;
    try {
      var success = true;
      for (final order in activeOrders) {
        if (!mounted || !_sharingWanted) return;
        final sent = await _service.updateShipperLocation(
          orderId: order.id!,
          shipperId: shipperId,
          latitude: position.latitude,
          longitude: position.longitude,
          bearing: position.heading.isFinite && position.heading >= 0
              ? position.heading
              : 0,
          speed: position.speed.isFinite && position.speed >= 0
              ? position.speed * 3.6
              : 0,
        );
        success = success && sent;
      }
      if (mounted)
        setState(() {
          if (success) _lastSent = DateTime.now();
          _gpsError = success
              ? null
              : 'Gửi vị trí thất bại. Kiểm tra kết nối API.';
        });
    } finally {
      _sending = false;
    }
  }

  Future<void> _act(OrderModel order, {required bool complete}) async {
    if (order.id == null || _busyOrder != null || _shipperId == null) return;
    setState(() => _busyOrder = order.id);
    try {
      final ok = complete
          ? await _service.completeOrder(order.id!)
          : await _service.acceptOrder(order.id!, _shipperId!);
      if (!ok) throw Exception('Không cập nhật được đơn hàng.');
      await _refresh();
      if (!complete && mounted) await _startGps();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _busyOrder = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Đơn giao hàng'),
      actions: [
        IconButton(
          tooltip: 'Tải lại',
          icon: const Icon(Icons.refresh),
          onPressed: _refresh,
        ),
        IconButton(
          tooltip: 'Ví shipper',
          icon: const Icon(Icons.account_balance_wallet_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WalletScreen()),
          ),
        ),
        AccountMenu(beforeLogout: () => _stopGps()),
      ],
    ),
    body: Column(
      children: [
        if (_orders.any((o) => o.status == 'Delivering'))
          SwitchListTile(
            title: const Text('Chia sẻ GPS khi giao hàng'),
            subtitle: Text(
              _startingGps
                  ? 'Đang lấy vị trí...'
                  : _sharing
                  ? (_lastSent == null
                        ? 'Đang chờ gửi vị trí'
                        : 'Đã gửi lúc ${_lastSent!.hour.toString().padLeft(2, '0')}:${_lastSent!.minute.toString().padLeft(2, '0')}')
                  : 'Bật để khách xem vị trí của bạn',
            ),
            value: _sharing,
            onChanged: _startingGps
                ? null
                : (value) {
                    if (value) {
                      _startGps();
                    } else {
                      _stopGps();
                    }
                  },
          ),
        if (_gpsError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_gpsError!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_orders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Chưa có đơn giao hàng.')),
                        ),
                      ..._orders.map(
                        (order) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đơn #${order.id}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  order.deliveryBuilding ??
                                      'Chưa có địa chỉ giao',
                                ),
                                Text('Trạng thái: ${order.status}'),
                                Text(
                                  'Tiền món: ${order.totalAmount.toStringAsFixed(0)} đ',
                                ),
                                const SizedBox(height: 12),
                                if (order.status == 'Delivering')
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.map),
                                        label: const Text('Chỉ đường'),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LiveTrackingScreen(
                                              orderId: order.id!,
                                              isShipper: true,
                                            ),
                                          ),
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: _busyOrder != null
                                            ? null
                                            : () => _act(order, complete: true),
                                        child: const Text('Đã giao hàng'),
                                      ),
                                    ],
                                  )
                                else
                                  FilledButton(
                                    onPressed: _busyOrder != null
                                        ? null
                                        : () => _act(order, complete: false),
                                    child: const Text('Nhận đơn'),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}
