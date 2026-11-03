import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/display_format.dart';
import '../../../../core/widgets/action_helpers.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  final OrderService? service;
  const MyOrdersScreen({super.key, this.service});
  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final _service = widget.service ?? OrderService();
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  int? _cancelling;
  bool _finished = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Vui lòng đăng nhập.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await _service.getBuyerOrders(userId);
      if (mounted) setState(() => _orders = orders);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(OrderModel order) async {
    if (!order.canCancel || order.id == null || _cancelling != null) return;
    final confirmed = await confirmAction(
      context,
      'Hủy đơn #${order.id}?',
      'Chỉ hủy được khi quán chưa xử lý. Đơn sẽ bị xóa khỏi lịch sử sau khi hủy.',
      label: 'Hủy đơn',
    );
    if (!confirmed || !mounted) return;
    setState(() => _cancelling = order.id);
    try {
      await _service.cancelOrder(order.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã hủy đơn hàng.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(e))));
      await _load();
    } finally {
      if (mounted) setState(() => _cancelling = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _orders.where((o) => o.isFinished == _finished).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Đang xử lý')),
                ButtonSegment(value: true, label: Text('Đã kết thúc')),
              ],
              selected: {_finished},
              onSelectionChanged: (value) =>
                  setState(() => _finished = value.single),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (visible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('Chưa có đơn hàng trong mục này.'),
                            ),
                          ),
                        ...visible.map(
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
                                  Text(order.statusLabel),
                                  Text(dateText(order.createdAt)),
                                  const SizedBox(height: 8),
                                  ...order.orderItems.map(
                                    (item) => Text(
                                      '${item.quantity}x ${item.productName ?? 'Món #${item.productId}'}',
                                    ),
                                  ),
                                  Text(
                                    order.deliveryBuilding ??
                                        'Chưa có địa chỉ giao',
                                  ),
                                  Text('Tiền món: ${money(order.totalAmount)}'),
                                  Text('Phí giao: ${money(order.shippingFee)}'),
                                  if (order.shippingFee != null)
                                    Text(
                                      'Tổng: ${money(order.totalAmount + order.shippingFee!)}',
                                    ),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: order.id == null
                                            ? null
                                            : () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        LiveTrackingScreen(
                                                          orderId: order.id!,
                                                        ),
                                                  ),
                                                );
                                                if (mounted) _load();
                                              },
                                        child: const Text(
                                          'Chi tiết / Theo dõi',
                                        ),
                                      ),
                                      if (order.canCancel)
                                        TextButton(
                                          onPressed: _cancelling != null
                                              ? null
                                              : () => _cancel(order),
                                          child: const Text('Hủy đơn'),
                                        ),
                                    ],
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
}
