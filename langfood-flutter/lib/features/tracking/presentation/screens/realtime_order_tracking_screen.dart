import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import 'live_tracking_screen.dart';

class RealtimeOrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const RealtimeOrderTrackingScreen({super.key, required this.orderId});
  @override
  State<RealtimeOrderTrackingScreen> createState() =>
      _RealtimeOrderTrackingScreenState();
}

class _RealtimeOrderTrackingScreenState
    extends State<RealtimeOrderTrackingScreen> {
  OrderModel? _order;
  bool _loading = true;
  bool _fetching = false;
  String? _error;
  Timer? _refreshTimer;
  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final order = await OrderService().getOrderById(widget.orderId);
      if (order == null) throw Exception('Không tải được đơn hàng.');
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _error = null;
      });
      if (order.status == 'Completed') _refreshTimer?.cancel();
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
    } finally {
      _fetching = false;
    }
  }

  String _status(String status) => switch (status) {
    'PendingPayment' => 'Chờ thanh toán',
    'Pending' => 'Chờ quán xác nhận',
    'Preparing' => 'Quán đang chuẩn bị',
    'Ready' => 'Chờ shipper nhận đơn',
    'PickingUp' => 'Shipper đang đến quán lấy món',
    'Delivering' => 'Đang giao hàng',
    'Completed' => 'Đã giao hàng',
    _ => status,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Đơn #${widget.orderId}'),
      actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_order != null) ...[
                Text(
                  _status(_order!.status),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(_order!.deliveryBuilding ?? 'Chưa có địa chỉ'),
                ..._order!.orderItems.map(
                  (item) => ListTile(
                    title: Text(item.productName ?? 'Món #${item.productId}'),
                    trailing: Text('x${item.quantity}'),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Xem vị trí giao hàng'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LiveTrackingScreen(orderId: widget.orderId),
                    ),
                  ),
                ),
              ],
            ],
          ),
  );
}
