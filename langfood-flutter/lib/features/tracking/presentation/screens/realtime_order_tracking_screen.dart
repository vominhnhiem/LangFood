import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../restaurant/presentation/screens/shop_orders_screen.dart';
import '../../../shipper/presentation/screens/shipper_orders_screen.dart';
import 'live_tracking_screen.dart';

class RealtimeOrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const RealtimeOrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<RealtimeOrderTrackingScreen> createState() => _RealtimeOrderTrackingScreenState();
}

class _RealtimeOrderTrackingScreenState extends State<RealtimeOrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  OrderModel? _order;
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    // Tự động kiểm tra cập nhật trạng thái từ Quán và Shipper mỗi 2 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _fetchOrder(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrder({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final res = await _orderService.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount).replaceAll(' ', '');
  }

  int _getStatusStep(String status) {
    switch (status) {
      case 'Pending':
      case 'PendingPayment':
        return 1;
      case 'Preparing':
        return 2;
      case 'Ready':
        return 3;
      case 'Delivering':
        return 4;
      case 'Completed':
        return 5;
      default:
        return 1;
    }
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
                const Text('Chuyển tài khoản để thao tác các bước tiếp theo của đơn hàng:'),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.school, color: Colors.white)),
                  title: const Text('1. Khách hàng (Sinh viên)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Đang ở màn hình theo dõi đơn hàng này'),
                  trailing: const Icon(Icons.check, color: Colors.green),
                  selected: true,
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.restaurant, color: Colors.white)),
                  title: const Text('2. Chủ quán ăn (Quán Cơm Tấm)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Bấm "Xác nhận nấu món" & "Món đã nấu xong"'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await authProvider.login('quanan', '1232123@');
                    if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopOrdersScreen()));
                    }
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.delivery_dining, color: Colors.white)),
                  title: const Text('3. Tài xế (Shipper)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Bấm "Nhận đơn" & "Giao hàng hoàn tất"'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await authProvider.login('shipper', '1232123@');
                    if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ShipperOrdersScreen()));
                    }
                  },
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
    final status = _order?.status ?? 'Pending';
    final currentStep = _getStatusStep(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Theo dõi đơn #LF-${widget.orderId}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
            tooltip: 'Đổi vai trò để duyệt đơn',
            onPressed: _showRoleSwitcherDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            tooltip: 'Tải lại',
            onPressed: () => _fetchOrder(),
          ),
        ],
      ),
      body: _isLoading && _order == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => _fetchOrder(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner chỉ dẫn Tester
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mẹo kiểm tra quy trình 3 vai trò:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                                const SizedBox(height: 2),
                                const Text(
                                  'Bấm icon ⇄ ở góc trên để chuyển sang Quán ăn (xác nhận/nấu) hoặc Shipper (nhận/giao). Màn hình này tự động cập nhật thời gian thực!',
                                  style: TextStyle(fontSize: 11, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card Trạng thái chính
                    _buildMainStatusCard(status, currentStep),
                    const SizedBox(height: 16),

                    // Timeline 5 bước
                    _buildTimelineCard(currentStep),
                    const SizedBox(height: 16),

                    // Chi tiết món ăn & Quán ăn
                    _buildOrderDetailsCard(),
                    const SizedBox(height: 20),

                    // Nút mở bản đồ định vị nếu đang giao
                    if (currentStep >= 4)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.map_rounded, color: Colors.white),
                          label: const Text(
                            'XEM VỊ TRÍ SHIPPER TRÊN BẢN ĐỒ',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveTrackingScreen(
                                  isShipper: false,
                                  orderCode: '#LF-${widget.orderId}',
                                  initialAddress: _order?.deliveryBuilding,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMainStatusCard(String status, int step) {
    String headline;
    String subline;
    Color color;
    IconData icon;

    switch (step) {
      case 1:
        headline = 'Đã gửi yêu cầu đến quán ăn 📝';
        subline = 'Quán Cơm Tấm đang xem đơn và chuẩn bị xác nhận...';
        color = const Color(0xFFE65100);
        icon = Icons.access_time_filled_rounded;
        break;
      case 2:
        headline = 'Quán đang nấu món ăn 🍳';
        subline = 'Món ăn của bạn đang được chế biến nóng hổi tại bếp...';
        color = const Color(0xFF1E88E5);
        icon = Icons.soup_kitchen_rounded;
        break;
      case 3:
        headline = 'Món đã nấu xong! 📦';
        subline = 'Bếp đã đóng gói xong. Đang chờ Shipper KTX đến nhận món...';
        color = const Color(0xFF7B1FA2);
        icon = Icons.takeout_dining_rounded;
        break;
      case 4:
        headline = 'Shipper đang trên đường giao 🛵';
        subline = 'Tài xế đã lấy món và đang di chuyển tới sảnh tòa nhà của bạn!';
        color = const Color(0xFF00897B);
        icon = Icons.delivery_dining_rounded;
        break;
      case 5:
        headline = 'Giao hàng thành công! 🎉';
        subline = 'Đơn hàng đã hoàn tất. Chúc bạn có một bữa ăn ngon miệng!';
        color = const Color(0xFF2E7D32);
        icon = Icons.check_circle_rounded;
        break;
      default:
        headline = 'Đang xử lý đơn hàng';
        subline = 'Hệ thống đang đồng bộ...';
        color = Colors.grey;
        icon = Icons.info_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            subline,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(int currentStep) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến trình Đơn hàng',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          _buildTimelineStep(1, 'Khách đặt món', 'Đã chuyển thông tin tới bếp', currentStep),
          _buildTimelineStep(2, 'Quán xác nhận & Nấu món', 'Bếp đang chế biến', currentStep),
          _buildTimelineStep(3, 'Món nấu xong (Báo Shipper)', 'Sẵn sàng tại quầy nhận món', currentStep),
          _buildTimelineStep(4, 'Shipper lấy món & Đang giao', 'Đang tới sảnh KTX của bạn', currentStep),
          _buildTimelineStep(5, 'Đã nhận hàng thành công', 'Hoàn tất giao nhận & thanh toán', currentStep, isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(int stepIndex, String title, String subtitle, int currentStep, {bool isLast = false}) {
    final isDone = currentStep > stepIndex;
    final isCurrent = currentStep == stepIndex;

    Color circleBg;
    if (isDone) {
      circleBg = const Color(0xFF2E7D32);
    } else if (isCurrent) {
      circleBg = AppColors.primary;
    } else {
      circleBg = Colors.grey.shade200;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$stepIndex',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: isDone ? const Color(0xFF2E7D32) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  color: isCurrent ? AppColors.primary : (isDone ? Colors.black87 : Colors.grey),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin Giao nhận',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Quán ăn: Quán Cơm Tấm Đêm KTX', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Giao đến: ${_order?.deliveryBuilding ?? "Sảnh KTX Khu B"}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'SĐT nhận: ${_order?.deliveryPhone ?? "0901234567"}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text('Món ăn trong đơn:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          if (_order != null && _order!.orderItems.isNotEmpty)
            ..._order!.orderItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('• ${item.quantity}x ${item.productName ?? "Món ngon"}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(_formatCurrency(item.unitPrice * item.quantity),
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              );
            })
          else
            const Text('Chi tiết 1 suất ăn', style: TextStyle(fontSize: 13)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                _formatCurrency((_order?.totalAmount ?? 0) + (_order?.shippingFee ?? 10000)),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
