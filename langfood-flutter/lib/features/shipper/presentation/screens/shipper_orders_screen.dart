import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/order_test_model.dart';
import '../../../../data/services/order_test_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';

class ShipperOrdersScreen extends StatefulWidget {
  const ShipperOrdersScreen({super.key});

  @override
  State<ShipperOrdersScreen> createState() => _ShipperOrdersScreenState();
}

class _ShipperOrdersScreenState extends State<ShipperOrdersScreen> {
  final OrderTestService _orderTestService = OrderTestService();
  List<OrderTestModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
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
    final shipperId = authProvider.user?.shipperId ?? 1;

    try {
      final list = await _orderTestService.getAvailableOrderTests(shipperId);
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptOrder(OrderTestModel order) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shipperId = authProvider.user?.shipperId ?? 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _orderTestService.acceptOrderTest(order.id!, shipperId);
      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhận đơn #${order.id} thành công! Mở bản đồ dẫn đường...'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(
              isShipper: true,
              initialCustomerPos: LatLng(order.latitude, order.longitude),
              initialAddress: order.deliveryAddress,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể nhận đơn: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Danh sách Đơn hàng (Shipper Demo)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại danh sách',
            onPressed: _fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Đăng xuất',
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
                          const SizedBox(height: 12),
                          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                            onPressed: _fetchOrders,
                          ),
                        ],
                      ),
                    ),
                  )
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.two_wheeler_outlined, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Chưa có đơn hàng Demo nào đang chờ nhận!',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('Bấm nút "Tải lại" phía trên để canh đơn mới từ khách hàng.',
                                style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              label: const Text('Tải lại danh sách đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: _fetchOrders,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.receipt_long_rounded, color: Colors.orange, size: 22),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Đơn Demo #${order.id ?? index + 1}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.orange.shade200),
                                        ),
                                        child: Text(
                                          order.status,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 18, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text('Khách: ${order.customerName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 18, color: Colors.red),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Địa chỉ: ${order.deliveryAddress}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 18, color: Colors.green),
                                      const SizedBox(width: 6),
                                      Text('SĐT: ${order.phone}', style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tổng tiền đơn hàng:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                          Text(
                                            _formatCurrency(order.totalAmount),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        icon: const Icon(Icons.directions_bike_rounded, size: 20),
                                        label: const Text('NHẬN ĐƠN NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
                                        onPressed: () => _acceptOrder(order),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
