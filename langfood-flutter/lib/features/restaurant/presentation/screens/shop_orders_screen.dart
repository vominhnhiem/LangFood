import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../shipper/presentation/screens/shipper_orders_screen.dart';

import '../../../../data/models/product_model.dart';
import '../../../../data/services/product_service.dart';

class ShopOrdersScreen extends StatefulWidget {
  const ShopOrdersScreen({super.key});

  @override
  State<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends State<ShopOrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  List<OrderModel> _orders = [];
  List<ProductModel> _shopProducts = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchOrders();
    _loadShopProducts();
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
    final shopId = authProvider.user?.shopId ?? 1;

    try {
      final list = await _orderService.getOrdersByShop(shopId);
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

  Future<void> _loadShopProducts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopId = authProvider.user?.shopId ?? 1;
    try {
      final prods = await _productService.getProductsByShop(shopId);
      if (mounted) {
        setState(() {
          _shopProducts = prods;
        });
      }
    } catch (e) {
      debugPrint('Load shop products error: $e');
    }
  }

  void _showAddDishDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopId = authProvider.user?.shopId ?? 1;

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    int selectedCatId = 1;
    String selectedImageUrl = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c';

    final presetImages = [
      {'label': 'Cơm sườn/đùi', 'url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c'},
      {'label': 'Bún/phở nước', 'url': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43'},
      {'label': 'Trà sữa/nước', 'url': 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd'},
      {'label': 'Ăn vặt KTX', 'url': 'https://images.unsplash.com/photo-1576107232684-1279f3908594'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.restaurant_menu_rounded, color: Color(0xFFE65100), size: 26),
                            SizedBox(width: 8),
                            Text(
                              'Đăng Món Ăn Mới',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Text(
                      'Món ăn sau khi đăng sẽ hiển thị trực tiếp cho Sinh viên đặt vào giỏ hàng ngay lập tức.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên món ăn (*)',
                        hintText: 'VD: Bún Chả Nướng Than Hoa KTX',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.fastfood_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Giá bán (VNĐ) (*)',
                        hintText: 'VD: 35000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.monetization_on_rounded),
                        suffixText: 'đ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Mô tả món ăn',
                        hintText: 'VD: Thịt nướng than hoa mềm thơm kèm rau sống, dưa chua, nước mắm...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.description_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Danh mục món ăn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Cơm & Mì'),
                          selected: selectedCatId == 1,
                          onSelected: (v) => setModalState(() => selectedCatId = 1),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Đồ uống'),
                          selected: selectedCatId == 2,
                          onSelected: (v) => setModalState(() => selectedCatId = 2),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Ăn vặt'),
                          selected: selectedCatId == 3,
                          onSelected: (v) => setModalState(() => selectedCatId = 3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Chọn ảnh món ăn mẫu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetImages.map((img) {
                        final isSel = selectedImageUrl == img['url'];
                        return InkWell(
                          onTap: () => setModalState(() => selectedImageUrl = img['url']!),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFE65100).withValues(alpha: 0.1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel ? const Color(0xFFE65100) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(img['url']!, width: 24, height: 24, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 6),
                                Text(img['label']!, style: TextStyle(fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final priceStr = priceController.text.trim();
                          final desc = descController.text.trim();

                          if (name.isEmpty || priceStr.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng nhập tên món và giá tiền!')),
                            );
                            return;
                          }

                          final price = double.tryParse(priceStr) ?? 0;
                          if (price <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Giá bán không hợp lệ!')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          _showActionLoading();

                          try {
                            await _productService.createProduct({
                              'name': name,
                              'price': price,
                              'description': desc,
                              'shopId': shopId,
                              'categoryId': selectedCatId,
                              'imageUrl': selectedImageUrl,
                            });

                            if (mounted) {
                              Navigator.pop(context); // Close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã đăng món "$name" thành công! Sinh viên đã có thể thấy trên menu.'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              await _loadShopProducts();
                              _tabController.animateTo(2); // Switch to menu tab
                            }
                          } catch (err) {
                            if (mounted) {
                              Navigator.pop(context); // Close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi đăng món: $err'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Text('ĐĂNG MÓN ĂN LÊN MENU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Quán xác nhận đơn & bắt đầu chế biến
  Future<void> _handleAcceptOrder(OrderModel order) async {
    if (order.id == null) return;
    _showActionLoading();
    final success = await _orderService.shopAcceptOrder(order.id!);
    if (mounted) Navigator.pop(context); // Close loading

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã nhận đơn #${order.id}! Bắt đầu nấu món...'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xác nhận đơn hàng lúc này'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Quán báo món đã nấu xong
  Future<void> _handleReadyOrder(OrderModel order) async {
    if (order.id == null) return;
    _showActionLoading();
    final success = await _orderService.shopReadyOrder(order.id!);
    if (mounted) Navigator.pop(context); // Close loading

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Món của đơn #${order.id} đã nấu xong! Đã báo Shipper tới lấy.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadData();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra khi chuyển trạng thái'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showActionLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                  subtitle: const Text('Đang đăng nhập màn hình này'),
                  trailing: const Icon(Icons.check, color: Colors.green),
                  selected: true,
                  onTap: () => Navigator.pop(ctx),
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.delivery_dining, color: Colors.white)),
                  title: const Text('3. Tài xế (Shipper)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Nhận đơn tại quán, giao tận tay sinh viên'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await authProvider.login('shipper', '1232123@');
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ShipperOrdersScreen()));
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
    final authProvider = Provider.of<AuthProvider>(context);
    final activeOrders = _orders.where((o) => o.status != 'Completed' && o.status != 'Cancelled').toList();
    final completedOrders = _orders.where((o) => o.status == 'Completed' || o.status == 'Cancelled').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bếp Quán Ăn (Quản lý đơn)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              authProvider.user?.shopName ?? 'Quán Cơm Tấm Đêm KTX',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE65100),
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
            Tab(text: 'Đang nấu (${activeOrders.length})'),
            Tab(text: 'Hoàn thành (${completedOrders.length})'),
            Tab(text: 'Thực đơn (${_shopProducts.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(activeOrders, isActiveTab: true),
          _buildOrderList(completedOrders, isActiveTab: false),
          _buildProductList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDishDialog,
        backgroundColor: const Color(0xFFE65100),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: const Text('Đăng món mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProductList() {
    if (_shopProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Chưa có món ăn nào trong thực đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Bấm nút "Đăng món mới" ở góc phải để thêm món ăn!'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddDishDialog,
              icon: const Icon(Icons.add),
              label: const Text('Đăng món đầu tiên'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShopProducts,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
        itemCount: _shopProducts.length,
        itemBuilder: (context, index) {
          final prod = _shopProducts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      prod.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 76,
                        height: 76,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                prod.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Text(
                                'Đang bán',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prod.description ?? 'Món ngon sinh viên KTX',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatCurrency(prod.price),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, {required bool isActiveTab}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 50),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                onPressed: _fetchOrders,
              ),
            ],
          ),
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActiveTab ? Icons.receipt_long_outlined : Icons.check_circle_outline,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              isActiveTab ? 'Chưa có đơn hàng nào cần chuẩn bị!' : 'Chưa có đơn hàng hoàn thành!',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              isActiveTab
                  ? 'Khi sinh viên đặt món từ giỏ hàng, đơn sẽ xuất hiện ở đây ngay lập tức.'
                  : 'Lịch sử các đơn đã hoàn thành giao hàng sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (order.status) {
      case 'Pending':
      case 'PendingPayment':
        statusColor = const Color(0xFFE65100);
        statusText = 'ĐƠN MỚI CHỜ NHẬN';
        statusIcon = Icons.notification_important_rounded;
        break;
      case 'Preparing':
        statusColor = const Color(0xFF1E88E5);
        statusText = 'BẾP ĐANG CHẾ BIẾN';
        statusIcon = Icons.soup_kitchen_rounded;
        break;
      case 'Ready':
        statusColor = const Color(0xFF7B1FA2);
        statusText = 'MÓN XONG • CHỜ SHIPPER';
        statusIcon = Icons.takeout_dining_rounded;
        break;
      case 'Delivering':
        statusColor = const Color(0xFF00897B);
        statusText = 'SHIPPER ĐANG GIAO';
        statusIcon = Icons.delivery_dining_rounded;
        break;
      case 'Completed':
        statusColor = const Color(0xFF2E7D32);
        statusText = 'ĐÃ GIAO THÀNH CÔNG';
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status.toUpperCase();
        statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 20),
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
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Khách hàng & Phòng KTX
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${order.buyerName ?? "Sinh viên KTX"} • SĐT: ${order.deliveryPhone ?? "Chưa có"}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 16, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.deliveryBuilding ?? 'Sảnh KTX Khu B',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Danh sách món ăn
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Món ăn đã đặt:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  if (order.orderItems.isEmpty)
                    const Text('Chi tiết 1 suất ăn', style: TextStyle(fontSize: 13))
                  else
                    ...order.orderItems.map((item) {
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
                    }),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tổng tiền & Phương thức thanh toán
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.paymentMethod == 0 ? '💵 Tiền mặt (COD)' : '💳 Đã chuyển khoản',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Tổng: ${_formatCurrency(order.totalAmount)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Nút hành động tương ứng với vai trò Quán
            if (order.status == 'Pending' || order.status == 'PendingPayment')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.soup_kitchen_rounded),
                  label: const Text('XÁC NHẬN & BẮT ĐẦU NẤU MÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _handleAcceptOrder(order),
                ),
              )
            else if (order.status == 'Preparing')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('MÓN ĐÃ NẤU XONG (BÁO SHIPPER LẤY)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _handleReadyOrder(order),
                ),
              )
            else if (order.status == 'Ready')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Color(0xFF7B1FA2), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Đang chờ Shipper KTX đến lấy món...',
                      style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (order.status == 'Delivering')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delivery_dining_rounded, color: Color(0xFF00897B), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Shipper đã lấy món và đang giao đến sảnh KTX',
                      style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
