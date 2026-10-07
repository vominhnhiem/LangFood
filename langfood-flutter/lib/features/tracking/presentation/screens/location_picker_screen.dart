import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../data/models/order_test_model.dart';
import '../../../../data/services/order_test_service.dart';
import 'live_tracking_screen.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedPosition = const LatLng(10.8800, 106.8050); // Default KTX Khu B, Thủ Đức
  String _addressText = 'Sảnh KTX Khu B, Thủ Đức';
  final TextEditingController _addressController = TextEditingController();
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = _addressText;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Lựa chọn 2: Định vị bản thân (GPS thực tế)
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng bật dịch vụ định vị (GPS) trên thiết bị!')),
          );
        }
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingGps = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền định vị bị từ chối vĩnh viễn. Vui lòng cấp quyền trong cài đặt.')),
          );
        }
        setState(() => _isLoadingGps = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = newLatLng;
        _addressText = 'Vị trí hiện tại (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        _addressController.text = _addressText;
        _isLoadingGps = false;
      });
      _mapController.move(newLatLng, 16.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lấy vị trí GPS: $e')),
        );
      }
      setState(() => _isLoadingGps = false);
    }
  }

  // Lựa chọn 1: Chọn trên bản đồ (Chạm vào bản đồ)
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPosition = point;
      _addressText = 'Tọa độ: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      _addressController.text = _addressText;
    });
  }

  // Lựa chọn 3: Nhập địa chỉ (TextField submit)
  void _onAddressSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      setState(() {
        _addressText = value.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật địa chỉ: $_addressText')),
      );
    }
  }

  // Xác nhận lần cuối để chốt chỗ đặt (Không cho dời chỗ khác nữa)
  void _showFinalConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Xác nhận chốt địa chỉ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn chọn địa chỉ này làm điểm nhận hàng cuối cùng?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Địa chỉ: $_addressText', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text('Tọa độ: ${_selectedPosition.latitude.toStringAsFixed(4)}, ${_selectedPosition.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Lưu ý: Sau khi xác nhận, điểm giao hàng sẽ bị KHÓA CỐ ĐỊNH và KHÔNG THỂ dời chỗ khác nữa!',
              style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chọn lại', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _finalizeOrderAndTracking();
            },
            child: const Text('Xác nhận chốt đơn'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeOrderAndTracking() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final customerName = authProvider.user?.fullName ?? authProvider.user?.username ?? 'Khách Demo';
      final phone = authProvider.user?.phoneNumber ?? '0987654321';
      final totalAmount = cartProvider.items.isNotEmpty ? cartProvider.totalAmount : 35000.0;

      final testOrder = OrderTestModel(
        customerName: customerName,
        deliveryAddress: _addressText,
        phone: phone,
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        totalAmount: totalAmount,
        status: 'Ready',
      );

      await OrderTestService().createOrderTest(testOrder);

      if (mounted) Navigator.pop(context); // Tắt loading

      cartProvider.clearCart(authProvider.user?.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo đơn hàng Demo thành công! Shipper đã có thể thấy đơn.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(
              isShipper: false,
              initialCustomerPos: _selectedPosition,
              initialAddress: _addressText,
              isLocationLocked: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo đơn demo: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn điểm nhận hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Bản đồ (Lựa chọn: Chọn trên bản đồ bằng cách chạm)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 16.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.langfood.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 50),
                  ),
                ],
              ),
            ],
          ),

          // 2. Ô nhập địa chỉ (Lựa chọn: Nhập địa chỉ)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập địa chỉ giao hàng...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: _onAddressSubmitted,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: AppColors.primary),
                      onPressed: () => _onAddressSubmitted(_addressController.text),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Nút Định vị bản thân (Lựa chọn: Bấm định vị bản thân)
          Positioned(
            top: 85,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              tooltip: 'Định vị bản thân',
              onPressed: _isLoadingGps ? null : _getCurrentLocation,
              child: _isLoadingGps
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
            ),
          ),

          // Hướng dẫn và Nút Xác nhận chốt đơn bên dưới
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📌 Tùy chọn đặt định vị:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Chạm vào bản đồ để chọn điểm\n• Bấm nút 🎯 để định vị bản thân\n• Nhập địa chỉ thủ công vào ô tìm kiếm trên',
                      style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.place, color: AppColors.primary, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _addressText,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showFinalConfirmationDialog,
                        child: const Text(
                          'Xác nhận chốt địa chỉ giao hàng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
