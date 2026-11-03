import '../../../../core/widgets/account_menu.dart';
import 'merchant_products_screen.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';

class ShopOrdersScreen extends StatefulWidget {
  const ShopOrdersScreen({super.key});
  @override
  State<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends State<ShopOrdersScreen> {
  final _service = OrderService();
  List<OrderModel> _orders = [];
  Timer? _timer;
  bool _loading = true;
  bool _fetching = false;
  int? _busyOrder;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_fetching) return;
    final shopId = context.read<AuthProvider>().user?.shopId;
    if (shopId == null) {
      setState(() {
        _loading = false;
        _error = 'Tài khoản chưa được gán quán ăn.';
      });
      return;
    }
    _fetching = true;
    try {
      final orders = await _service.getOrdersByShop(shopId);
      if (mounted)
        setState(() {
          _orders = orders;
          _loading = false;
          _error = null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
    } finally {
      _fetching = false;
    }
  }

  Future<void> _advance(OrderModel order) async {
    if (order.id == null || _busyOrder != null) return;
    setState(() => _busyOrder = order.id);
    try {
      final ok = order.status == 'Pending'
          ? await _service.shopAcceptOrder(order.id!)
          : await _service.shopReadyOrder(order.id!);
      if (!ok) throw Exception('Không cập nhật được đơn hàng.');
      await _refresh();
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
      title: const Text('Đơn của quán'),
      actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        IconButton(
          tooltip: 'Quản lý menu',
          icon: const Icon(Icons.restaurant_menu),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MerchantProductsScreen()),
          ),
        ),
        const AccountMenu(),
      ],
    ),
    body: _loading
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
                  const Center(child: Text('Chưa có đơn hàng.')),
                ..._orders.map(
                  (order) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn #${order.id}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('Trạng thái: ${order.status}'),
                          ...order.orderItems.map(
                            (item) => Text(
                              '${item.quantity}x ${item.productName ?? 'Món #${item.productId}'}',
                            ),
                          ),
                          if (order.status == 'Pending' ||
                              order.status == 'Preparing')
                            FilledButton(
                              onPressed: _busyOrder != null
                                  ? null
                                  : () => _advance(order),
                              child: Text(
                                order.status == 'Pending'
                                    ? 'Xác nhận chế biến'
                                    : 'Món đã sẵn sàng',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
  );
}
