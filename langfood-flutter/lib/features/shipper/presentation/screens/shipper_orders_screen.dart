import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../restaurant/presentation/screens/shop_orders_screen.dart';
import '../../../tracking/presentation/screens/live_tracking_screen.dart';

class ShipperOrdersScreen extends StatefulWidget {
  const ShipperOrdersScreen({super.key});

  @override
  State<ShipperOrdersScreen> createState() => _ShipperOrdersScreenState();
}

class _ShipperOrdersScreenState extends State<ShipperOrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
    // Tự động kiểm tra đơn hàng mới mỗi 3 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _silentRefresh();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
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
    await _loadData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _silentRefresh() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shipperId = authProvider.user?.shipperId ?? 1;

    try {
      final list = await _orderService.getOrdersForShipper(shipperId);
      if (mounted) {
        setState(() {
          _orders = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && _isLoading) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  // Shipper bấm Nhận đơn hàng (Đến quán lấy món)
  Future<void> _handleAcceptOrder(OrderModel order) async {
    if (order.id == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shipperId = authProvider.user?.shipperId ?? 1;

    _showActionLoading();
    try {
      final success = await _orderService.acceptOrder(order.id!, shipperId);
      if (mounted) Navigator.pop(context); // Close loading

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã nhận đơn #${order.id}! Hãy đến quán lấy món và giao cho khách.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadData();
        }
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

  // Shipper bấm Đã giao món cho khách (Hoàn tất đơn hàng)
  Future<void> _handleCompleteOrder(OrderModel order) async {
    if (order.id == null) return;
    _showActionLoading();
    final success = await _orderService.completeOrder(order.id!);
    if (mounted) Navigator.pop(context); // Close loading

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chúc mừng! Đơn hàng #${order.id} đã hoàn tất. Tiền công ship +10.000đ đã vào ví!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        _loadData();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi khi cập nhật hoàn tất đơn'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Shipper cập nhật vị trí GPS thực gửi đến khách hàng
  Future<void> _updateShipperGps(int orderId, double lat, double lng, String note) async {
    final success = await _orderService.updateShipperLocation(
      orderId: orderId,
      latitude: lat,
      longitude: lng,
      speedKmh: 24.0,
      headingDegree: 45.0,
      statusNote: note,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '📍 Đã cập nhật GPS: $note' : 'Không thể cập nhật tọa độ GPS'),
          backgroundColor: success ? Colors.blue.shade700 : AppColors.error,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showActionLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );
  }

  void _showRoleSwitcherDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chuyển đổi Vai trò (Tester Switcher)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text('Chuyển nhanh giữa 3 tài khoản để kiểm tra quy trình đặt món:'),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.school, color: Colors.white)),
                  title: const Text('1. Khách hàng (Sinh viên)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Đặt món, chọn phòng KTX, theo dõi đơn'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await authProvider.login('sinhvien', '1232123@');
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                    }
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.restaurant, color: Colors.white)),
                  title: const Text('2. Chủ quán ăn (Quán Cơm Tấm)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Nhận đơn từ khách, xác nhận và nấu món'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await authProvider.login('quanan', '1232123@');
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ShopOrdersScreen()));
                    }
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.delivery_dining, color: Colors.white)),
                  title: const Text('3. Tài xế (Shipper)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Đang đăng nhập màn hình này'),
                  trailing: const Icon(Icons.check, color: Colors.green),
                  selected: true,
                  onTap: () => Navigator.pop(ctx),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final shipperId = authProvider.user?.shipperId ?? 1;

    // Đơn đang giao của chính mình
    final deliveringOrders = _orders.where((o) => o.status == 'Delivering' && o.shipperId == shipperId).toList();
    // Đơn quán đã nấu xong sẵn sàng cho nhận
    final availableOrders = _orders.where((o) => o.status == 'Ready' || o.status == 'Confirmed' || o.status == 'Accepted').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tài xế KTX (Giao hàng)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${authProvider.user?.fullName ?? "Lê Văn Shipper"} • MSSV: 20120123',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            tooltip: 'Đổi vai trò',
            onPressed: _showRoleSwitcherDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Tải lại',
            onPressed: _fetchOrders,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Đang giao (${deliveringOrders.length})'),
            Tab(text: 'Đơn chờ nhận (${availableOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDeliveringTab(deliveringOrders),
          _buildAvailableTab(availableOrders),
        ],
      ),
    );
  }

  Widget _buildDeliveringTab(List<OrderModel> orders) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.two_wheeler_rounded, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              'Bạn chưa nhận đơn hàng nào đang giao!',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy chuyển sang tab "Đơn chờ nhận" để chọn đơn món đã nấu xong.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildShipperOrderCard(order, isDelivering: true);
        },
      ),
    );
  }

  Widget _buildAvailableTab(List<OrderModel> orders) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              'Hiện chưa có đơn nào quán nấu xong đang chờ lấy!',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Khi Quán ăn bấm "Món đã nấu xong (Báo Shipper)", đơn sẽ lập tức xuất hiện tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildShipperOrderCard(order, isDelivering: false);
        },
      ),
    );
  }

  Widget _buildShipperOrderCard(OrderModel order, {required bool isDelivering}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDelivering ? Colors.green.shade50 : Colors.purple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDelivering ? Icons.delivery_dining_rounded : Icons.takeout_dining_rounded,
                        color: isDelivering ? Colors.green.shade700 : Colors.purple.shade700,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đơn hàng #LF-${order.id ?? ""}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivering ? Colors.green.shade50 : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDelivering ? Colors.green.shade200 : Colors.purple.shade200),
                  ),
                  child: Text(
                    isDelivering ? 'ĐANG GIAO' : 'MÓN ĐÃ NẤU XONG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDelivering ? Colors.green.shade800 : Colors.purple.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Điểm lấy món (Quán ăn)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.storefront_rounded, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Điểm lấy món (Quán ăn):', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const Text(
                        'Quán Cơm Tấm Đêm KTX (Nhà ăn Tòa B4, KTX Khu B)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Điểm giao món (Khách hàng)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.pin_drop_rounded, size: 18, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Giao tới cho sinh viên:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text(
                        '${order.deliveryBuilding ?? "Sảnh KTX Khu B"} (${order.buyerName ?? "Sinh viên"})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (order.deliveryPhone != null && order.deliveryPhone!.isNotEmpty)
                        Text('SĐT khách: ${order.deliveryPhone}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Thu nhập và tiền thu hộ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Thu tiền khách (COD):', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      Text(
                        order.paymentMethod == 0 ? _formatCurrency(order.totalAmount + order.shippingFee) : '0đ (Đã chuyển khoản)',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Công ship bạn nhận:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      const Text(
                        '+10.000đ',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Nút hành động
            if (!isDelivering)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.two_wheeler_rounded),
                  label: const Text('NHẬN ĐƠN NÀY (ĐẾN QUÁN LẤY MÓN)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _handleAcceptOrder(order),
                ),
              )
            else ...[
              // BỘ ĐIỀU KHIỂN GPS THỰC TẾ CHO SHIPPER
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.gps_fixed_rounded, color: Colors.blue, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'ĐỒNG BỘ VỊ TRÍ GPS THỰC (Báo tới khách):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bấm vào các mốc để cập nhật tọa độ GPS thực tế của bạn đến bản đồ của khách hàng:',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.store, size: 16, color: Colors.deepOrange),
                          label: const Text('1. Tại Quán'),
                          onPressed: () => _updateShipperGps(order.id!, 10.8818, 106.8042, 'Đang lấy món tại quán ăn'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.two_wheeler, size: 16, color: Colors.indigo),
                          label: const Text('2. Tạ Quang Bửu'),
                          onPressed: () => _updateShipperGps(order.id!, 10.8810, 106.8058, 'Đang đi qua đường Tạ Quang Bửu'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.apartment, size: 16, color: Colors.purple),
                          label: const Text('3. Cổng KTX'),
                          onPressed: () => _updateShipperGps(order.id!, 10.8816, 106.8071, 'Đã tới cổng KTX Khu B'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.location_on, size: 16, color: Colors.green),
                          label: const Text('4. Tới Sảnh BA2'),
                          onPressed: () => _updateShipperGps(order.id!, 10.8828, 106.8080, 'Đã tới chân thang máy sảnh Tòa BA2'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Bản đồ'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LiveTrackingScreen(
                              isShipper: true,
                              orderCode: '#LF-${order.id}',
                              orderId: order.id,
                              initialAddress: order.deliveryBuilding,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('ĐÃ GIAO XONG (HOÀN TẤT)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _handleCompleteOrder(order),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
