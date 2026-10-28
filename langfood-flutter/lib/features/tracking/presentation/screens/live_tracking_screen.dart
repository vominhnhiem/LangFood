import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../shipper/presentation/screens/shipper_orders_screen.dart';

/// Enum representing the 4 real-time delivery stages of LangFood Campus Express
enum LF08TrackingStage {
  preparing, // Bếp đang chế biến (2 quán)
  pickingUp, // Shipper đang lấy hàng gộp 2 quán
  delivering, // Shipper đang phóng xe tới Sảnh KTX
  arrived, // Shipper đã tới sảnh tầng G BA2
}

/// Các chế độ bản đồ không watermark (100% Esri ArcGIS miễn phí, độ nét cao)
enum MapLayerType {
  streets, // Bản đồ đường phố KTX (ArcGIS World Street)
  dark, // Bản đồ đêm sang trọng (ArcGIS World Dark Gray Base - KHÔNG WATERMARK)
  satellite, // Ảnh vệ tinh thực địa ĐHQG (ArcGIS World Imagery)
}

enum _LF08HapticType {
  light,
  medium,
  selection,
}

class LiveTrackingScreen extends StatefulWidget {
  final bool isShipper;
  final LatLng? initialCustomerPos;
  final String? initialAddress;
  final bool isLocationLocked;
  final String orderCode;
  final int? orderId;

  const LiveTrackingScreen({
    super.key,
    this.isShipper = false,
    this.initialCustomerPos,
    this.initialAddress,
    this.isLocationLocked = true,
    this.orderCode = '#LF-8924',
    this.orderId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  // Map Controller
  final MapController _mapController = MapController();
  final OrderService _orderService = OrderService();
  OrderModel? _realOrder;
  Timer? _realLocationPollTimer;

  // Coordinates around KTX Khu B - ĐHQG TP.HCM (Đồng bộ chuẩn xác với LF-06)
  // 1. Quán 1 - Cơm Gà Da Giòn Bà Tám (Cổng sau KTX B)
  final LatLng _shop1Pos = const LatLng(10.8818, 106.8042);
  // 2. Quán 2 - Trà Sữa Nướng Vân Nam (Tòa B4 Làng ĐH)
  final LatLng _shop2Pos = const LatLng(10.8801, 106.8062);
  // 3. Điểm giao: Tòa BA2 - KTX Khu B ĐHQG (Sảnh G)
  late LatLng _destinationPos;

  // Active moving Shipper position
  late LatLng _currentShipperPos;
  double _shipperBearing = 45.0;

  // Delivery Stages & Controls
  LF08TrackingStage _currentStage = LF08TrackingStage.delivering;
  MapLayerType _selectedMapType = MapLayerType.streets;
  bool _isDarkMode = false;
  bool _showChatSheet = false;
  bool _showCallingDialog = false;
  bool _showRoommateSheet = false;
  bool _showSosSheet = false;

  // Animation controller for Shipper vehicle movement
  late AnimationController _pulseController;
  late AnimationController _moveAnimController;
  Timer? _simulatedMovementTimer;
  int _routeStepIndex = 0;

  // Route coordinates
  late List<LatLng> _fullRouteCoordinates;

  // Real-time delivery parameters
  int _estimatedMinutes = 12;
  double _remainingKm = 0.85;
  double _currentSpeedKmH = 24.5; // Vận tốc thực tế shipper ~25 km/h đường nội bộ

  // Roommate Pickup Pin
  final String _roommatePin = '7821';

  // Chat message history for student <-> shipper
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'sender': 'system',
      'text': 'Đơn hàng #LF-8924 đã được ghép tài xế KTX Trần Quốc Huy (BK K21).',
      'time': '12:02',
    },
    {
      'sender': 'shipper',
      'text': 'Chào bạn Minh, mình đã lấy đủ cơm Bà Tám & trà sữa Vân Nam rồi nhé! Đang chạy về sảnh BA2 ạ 🛵',
      'time': '12:14',
    },
    {
      'sender': 'student',
      'text': 'Dạ vâng anh, em ở phòng 512, khi nào tới chân thang máy sảnh G nhá máy em nhé!',
      'time': '12:15',
    },
  ];
  final TextEditingController _chatInputController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _destinationPos = widget.initialCustomerPos ?? const LatLng(10.8828, 106.8080);
    _currentShipperPos = const LatLng(10.8809, 106.8066);

    // Build the realistic campus route line connecting Quán 1 -> Quán 2 -> KTX BA2
    _fullRouteCoordinates = [
      _shop1Pos,
      const LatLng(10.8814, 106.8048),
      const LatLng(10.8807, 106.8055),
      _shop2Pos,
      const LatLng(10.8809, 106.8066),
      const LatLng(10.8816, 106.8071),
      const LatLng(10.8822, 106.8076),
      _destinationPos,
    ];

    // Pulsing radar animation for Shipper marker
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Movement animation controller
    _moveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Tải thông tin đơn hàng thật
    if (widget.orderId != null) {
      _loadRealOrder(widget.orderId!);
    }

    // ĐỒNG BỘ THEO VỊ TRÍ THỰC CỦA SHIPPER (KHÔNG TỰ DI CHUYỂN BẰNG MOCK TIMER)
    _startRealShipperTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _moveAnimController.dispose();
    _realLocationPollTimer?.cancel();
    _chatInputController.dispose();
    super.dispose();
  }

  Future<void> _loadRealOrder(int orderId) async {
    try {
      final order = await _orderService.getOrderById(orderId);
      if (mounted && order != null) {
        setState(() {
          _realOrder = order;
          if (order.status == 'Preparing') {
            _currentStage = LF08TrackingStage.preparing;
          } else if (order.status == 'Ready') {
            _currentStage = LF08TrackingStage.pickingUp;
          } else if (order.status == 'Delivering') {
            _currentStage = LF08TrackingStage.delivering;
          } else if (order.status == 'Completed') {
            _currentStage = LF08TrackingStage.arrived;
          }
        });
      }
    } catch (_) {}
  }

  void _triggerHaptic([_LF08HapticType type = _LF08HapticType.light]) {
    try {
      if (type == _LF08HapticType.selection) {
        HapticFeedback.selectionClick();
      } else if (type == _LF08HapticType.medium) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void _startRealShipperTracking() {
    _realLocationPollTimer?.cancel();
    _pollShipperLocation();
    _realLocationPollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollShipperLocation();
    });
  }

  Future<void> _pollShipperLocation() async {
    if (!mounted) return;
    final targetId = widget.orderId ?? 1;
    final loc = await _orderService.getShipperLocation(targetId);
    if (loc != null && mounted) {
      final double lat = (loc['latitude'] as num).toDouble();
      final double lng = (loc['longitude'] as num).toDouble();
      final double bearing = (loc['bearing'] as num?)?.toDouble() ?? _shipperBearing;
      final double speed = (loc['speed'] as num?)?.toDouble() ?? 0.0;

      // Chỉ cập nhật khi tọa độ thực tế từ Shipper thay đổi
      if (lat != _currentShipperPos.latitude || lng != _currentShipperPos.longitude) {
        setState(() {
          _currentShipperPos = LatLng(lat, lng);
          _shipperBearing = bearing;
          _currentSpeedKmH = speed > 0 ? speed : 22.0;

          final distM = const Distance().as(LengthUnit.Meter, _currentShipperPos, _destinationPos);
          _remainingKm = (distM / 1000.0);
          _estimatedMinutes = math.max(1, (distM / 350).ceil());
        });
        _mapController.move(_currentShipperPos, _mapController.camera.zoom);
      }
    }
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * (math.pi / 180.0);
    final lon1 = start.longitude * (math.pi / 180.0);
    final lat2 = end.latitude * (math.pi / 180.0);
    final lon2 = end.longitude * (math.pi / 180.0);

    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final radians = math.atan2(y, x);
    return (radians * (180.0 / math.pi) + 360.0) % 360.0;
  }

  void _recenterMap() {
    _triggerHaptic(_LF08HapticType.selection);
    _mapController.move(_currentShipperPos, 16.5);
  }

  void _fitCampusBounds() {
    _triggerHaptic(_LF08HapticType.selection);
    _mapController.move(
      LatLng(
        (_currentShipperPos.latitude + _destinationPos.latitude) / 2,
        (_currentShipperPos.longitude + _destinationPos.longitude) / 2,
      ),
      15.8,
    );
  }

  void _setStage(LF08TrackingStage stage) {
    _triggerHaptic(_LF08HapticType.medium);
    setState(() {
      _currentStage = stage;
      if (stage == LF08TrackingStage.preparing) {
        _estimatedMinutes = 22;
        _remainingKm = 1.4;
        _currentSpeedKmH = 0.0;
        _currentShipperPos = _shop1Pos;
      } else if (stage == LF08TrackingStage.pickingUp) {
        _estimatedMinutes = 16;
        _remainingKm = 1.1;
        _currentSpeedKmH = 15.0;
        _currentShipperPos = _shop2Pos;
      } else if (stage == LF08TrackingStage.delivering) {
        _estimatedMinutes = 8;
        _remainingKm = 0.5;
        _currentSpeedKmH = 24.5;
        _currentShipperPos = const LatLng(10.8816, 106.8071);
      } else if (stage == LF08TrackingStage.arrived) {
        _estimatedMinutes = 0;
        _remainingKm = 0.0;
        _currentSpeedKmH = 0.0;
        // Đặt Shipper ngay cửa sảnh BA2 (cách 35m) để 2 pin không bị đè che nhau
        _currentShipperPos = LatLng(_destinationPos.latitude - 0.00035, _destinationPos.longitude - 0.00035);
        _showArrivedNotificationDialog();
      }
    });
  }

  void _showArrivedNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Shipper đã đến Sảnh KTX! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tài xế Trần Quốc Huy đang đợi bạn tại sảnh Tầng G (Chân thang máy) Tòa BA2 KTX Khu B.\nVui lòng mang theo điện thoại để nhận món!',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('TÔI XUỐNG NGAY!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    _triggerHaptic(_LF08HapticType.light);
    setState(() {
      _chatMessages.add({
        'sender': 'student',
        'text': text.trim(),
        'time': 'Vừa xong',
      });
      _chatInputController.clear();
    });

    // Simulate Shipper quick response
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _chatMessages.add({
          'sender': 'shipper',
          'text': 'Dạ em nghe bạn Minh ơi! Em đang chạy vào sảnh BA2 rồi ạ, 2 phút nữa tới nơi 👍',
          'time': 'Vừa xong',
        });
      });
      _triggerHaptic(_LF08HapticType.selection);
    });
  }

  String _getMapTileUrl() {
    switch (_selectedMapType) {
      case MapLayerType.dark:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
      case MapLayerType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayerType.streets:
      default:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  void _cycleMapLayer() {
    _triggerHaptic(_LF08HapticType.selection);
    setState(() {
      if (_selectedMapType == MapLayerType.streets) {
        _selectedMapType = MapLayerType.dark;
        _isDarkMode = true;
      } else if (_selectedMapType == MapLayerType.dark) {
        _selectedMapType = MapLayerType.satellite;
      } else {
        _selectedMapType = MapLayerType.streets;
        _isDarkMode = false;
      }
    });

    String layerName;
    if (_selectedMapType == MapLayerType.dark) {
      layerName = '🌙 Bản đồ Đêm (Dark Radar - 0 Watermark)';
    } else if (_selectedMapType == MapLayerType.satellite) {
      layerName = '🛰️ Ảnh vệ tinh khuôn viên ĐHQG';
    } else {
      layerName = '🗺️ Bản đồ đường phố KTX';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(layerName),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = _isDarkMode ? const Color(0xFF101012) : const Color(0xFFF8F9FA);
    final themeCard = _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final themeTextPrimary = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final themeTextSecondary = _isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF64748B);
    final themeBorder = _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: themeBg,
      body: Stack(
        children: [
          // 1. Fullscreen Vector Campus Map (100% Watermark-free)
          _buildCampusMap(),

          // 2. Top Safe Area: Header & Live Hero Arrival Card
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Inspector Switcher Bar
                _buildTopInspectorBar(themeCard, themeTextPrimary, themeBorder),
                const SizedBox(height: 8),

                // Apple HIG Frosted Glass Header
                _buildFrostedHeader(themeCard, themeTextPrimary, themeBorder),
                const SizedBox(height: 10),

                // Live Hero Arrival Card (Live Activity & Dynamic Island Banner)
                _buildLiveHeroArrivalCard(),
              ],
            ),
          ),

          // 3. Map Floating Action Buttons (Recenter, Fit Campus, Map Layer Switcher)
          Positioned(
            right: 16,
            bottom: 300,
            child: Column(
              children: [
                // Map Layer Switcher Button
                FloatingActionButton.small(
                  heroTag: 'map_layer_btn',
                  backgroundColor: themeCard,
                  foregroundColor: _selectedMapType == MapLayerType.dark ? Colors.amber : const Color(0xFF2563EB),
                  elevation: 4,
                  onPressed: _cycleMapLayer,
                  tooltip: 'Đổi kiểu bản đồ',
                  child: Icon(
                    _selectedMapType == MapLayerType.dark
                        ? Icons.nightlight_round
                        : (_selectedMapType == MapLayerType.satellite
                            ? Icons.satellite_alt_rounded
                            : Icons.layers_rounded),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),

                // Recenter to Shipper
                FloatingActionButton.small(
                  heroTag: 'recenter_btn',
                  backgroundColor: themeCard,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  onPressed: _recenterMap,
                  tooltip: 'Định vị Shipper',
                  child: const Icon(Icons.my_location_rounded, size: 20),
                ),
                const SizedBox(height: 8),

                // Fit Campus Bounds
                FloatingActionButton.small(
                  heroTag: 'bounds_btn',
                  backgroundColor: themeCard,
                  foregroundColor: const Color(0xFF10B981),
                  elevation: 4,
                  onPressed: _fitCampusBounds,
                  tooltip: 'Xem toàn cảnh chặng',
                  child: const Icon(Icons.fit_screen_rounded, size: 20),
                ),
              ],
            ),
          ),

          // 4. Draggable Bottom Sheet with Multi-Shop Stepper & Details
          _buildDraggableTrackingSheet(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),

          // 5. In-App Quick Chat Modal Sheet
          if (_showChatSheet)
            _buildChatModal(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),

          // 6. Shipper Call Dialog Modal
          if (_showCallingDialog)
            _buildCallDialog(themeCard, themeTextPrimary),

          // 7. Roommate Pickup Share Modal Sheet
          if (_showRoommateSheet)
            _buildRoommateShareModal(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),

          // 8. SOS Emergency Report Sheet
          if (_showSosSheet)
            _buildSosReportModal(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
        ],
      ),
    );
  }

  // ================= 1. CAMPUS MAP =================
  Widget _buildCampusMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _destinationPos,
        initialZoom: 16.5,
        minZoom: 14.0,
        maxZoom: 18.5,
      ),
      children: [
        // Basemap: 100% Watermark-free Esri ArcGIS Base Layers
        TileLayer(
          urlTemplate: _getMapTileUrl(),
          userAgentPackageName: 'vn.langfood.campus',
        ),

        // Route polyline connecting Quán 1 -> Quán 2 -> KTX BA2
        PolylineLayer(
          polylines: [
            // Shadow outline
            Polyline(
              points: _fullRouteCoordinates,
              strokeWidth: 8.0,
              color: Colors.black.withOpacity(0.22),
            ),
            // Glowing neon route
            Polyline(
              points: _fullRouteCoordinates,
              strokeWidth: 5.5,
              color: _isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
              borderColor: Colors.white,
              borderStrokeWidth: 1.5,
            ),
          ],
        ),

        // Markers Layer (Quán 1, Quán 2, KTX Destination, and Moving Shipper)
        MarkerLayer(
          markers: [
            // Quán 1 - Cơm Gà Bà Tám
            Marker(
              point: _shop1Pos,
              width: 120,
              height: 60,
              alignment: Alignment.topCenter,
              child: _buildShopMarker('🍗', 'Cơm Bà Tám'),
            ),

            // Quán 2 - Trà Sữa Vân Nam
            Marker(
              point: _shop2Pos,
              width: 130,
              height: 60,
              alignment: Alignment.topCenter,
              child: _buildShopMarker('🧋', 'Trà Sữa Vân Nam'),
            ),

            // Điểm giao: KTX BA2 Sảnh G
            Marker(
              point: _destinationPos,
              width: 140,
              height: 65,
              alignment: Alignment.topCenter,
              child: _buildDestinationMarker(),
            ),

            // Moving Shipper with animated radar ripple ring
            Marker(
              point: _currentShipperPos,
              width: 100,
              height: 80,
              alignment: Alignment.center,
              child: _buildAnimatedShipperMarker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShopMarker(String emoji, String title) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC2410C),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, color: Colors.white, size: 11),
              SizedBox(width: 3),
              Text(
                'BA2 Sảnh G',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF10B981), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.apartment_rounded, color: Color(0xFF10B981), size: 16),
        ),
      ],
    );
  }

  Widget _buildAnimatedShipperMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.35);
        final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Text(
                '🛵 Shipper Huy (K21)',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 2),
            Stack(
              alignment: Alignment.center,
              children: [
                // Radar pulse ring
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(opacity * 0.4),
                    ),
                  ),
                ),
                // Outer badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ================= 2. TOP INSPECTOR & HEADER =================
  Widget _buildTopInspectorBar(Color card, Color textPrimary, Color border) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.radar_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              'LF-08 Stages:',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),

            _buildStageChip(LF08TrackingStage.preparing, '1. Nấu món', Icons.restaurant_rounded),
            const SizedBox(width: 5),
            _buildStageChip(LF08TrackingStage.pickingUp, '2. Lấy 2 quán', Icons.shopping_bag_rounded),
            const SizedBox(width: 5),
            _buildStageChip(LF08TrackingStage.delivering, '3. Đang giao', Icons.two_wheeler_rounded),
            const SizedBox(width: 5),
            _buildStageChip(LF08TrackingStage.arrived, '4. Đã đến sảnh', Icons.check_circle_rounded),
            const SizedBox(width: 8),

            // Dark Mode toggle
            InkWell(
              onTap: () {
                _triggerHaptic(_LF08HapticType.selection);
                setState(() {
                  _isDarkMode = !_isDarkMode;
                  _selectedMapType = _isDarkMode ? MapLayerType.dark : MapLayerType.streets;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.amber.withOpacity(0.2) : Colors.indigo.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      size: 11,
                      color: _isDarkMode ? Colors.amber : Colors.white,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _isDarkMode ? 'Light' : 'Dark',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.amber : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageChip(LF08TrackingStage stage, String label, IconData icon) {
    final isSelected = _currentStage == stage;
    return InkWell(
      onTap: () => _setStage(stage),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedHeader(Color card, Color textPrimary, Color border) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: card.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            children: [
              // Back Button (Returns to Shipper Screen if Shipper, or Home if Student)
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF08HapticType.selection);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final isShipperRole = widget.isShipper || (authProvider.user?.isShipper ?? false);
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else if (isShipperRole) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ShipperOrdersScreen()),
                    );
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: textPrimary),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Đơn hàng & Trạng thái',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Trực tiếp 🟢',
                            style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _realOrder != null
                          ? '#LF-${_realOrder!.id} • ${_realOrder!.deliveryBuilding ?? "KTX Khu B"}'
                          : '${widget.orderCode} • Sảnh BA2',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // SOS KTX button
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF08HapticType.medium);
                  setState(() => _showSosSheet = true);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emergency_rounded, size: 13, color: Colors.red),
                      SizedBox(width: 3),
                      Text('SOS KTX', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 3. LIVE HERO ARRIVAL CARD =================
  Widget _buildLiveHeroArrivalCard() {
    String indicatorText;
    int activeSegment;

    switch (_currentStage) {
      case LF08TrackingStage.preparing:
        indicatorText = 'Bếp 2 quán đang nấu món nóng hổi • Đang chuẩn bị đóng gói';
        activeSegment = 1;
        break;
      case LF08TrackingStage.pickingUp:
        indicatorText = 'Shipper đang lấy đồ gộp 2 quán • Kiểm tra túi giữ nhiệt';
        activeSegment = 2;
        break;
      case LF08TrackingStage.delivering:
        indicatorText = 'Shipper đang trên đường tới sảnh Tòa BA2 • Đang rẽ qua Đường Tạ Quang Bửu - KTX Khu B';
        activeSegment = 3;
        break;
      case LF08TrackingStage.arrived:
        indicatorText = 'Shipper đã tới chân thang máy Sảnh G BA2! • Vui lòng xuống nhận đồ';
        activeSegment = 4;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Big Arrival Countdown & Speed
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'DỰ KIẾN GIAO: ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white60,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '⚡ ${_currentSpeedKmH.toStringAsFixed(0)} km/h nội bộ',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF60A5FA), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _currentStage == LF08TrackingStage.arrived ? 'ĐÃ ĐẾN NƠI (12:28)' : '12:25 (Còn ~$_estimatedMinutes phút)',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dynamic Island Live Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.two_wheeler_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _currentStage == LF08TrackingStage.arrived ? 'SẢNH G' : '$_remainingKm KM',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Real-time Arrival Indicator
              Row(
                children: [
                  const Icon(Icons.navigation_rounded, size: 13, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      indicatorText,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Multi-segmented Progress Bar (4 sections)
              _buildSegmentedProgressBar(activeSegment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedProgressBar(int activeSegment) {
    return Row(
      children: [
        _buildProgressSegment(1, activeSegment, 'Nhận đơn'),
        const SizedBox(width: 4),
        _buildProgressSegment(2, activeSegment, 'Nấu 2 quán'),
        const SizedBox(width: 4),
        _buildProgressSegment(3, activeSegment, 'Đang tới'),
        const SizedBox(width: 4),
        _buildProgressSegment(4, activeSegment, 'Sảnh G'),
      ],
    );
  }

  Widget _buildProgressSegment(int step, int activeSegment, String label) {
    final isDone = activeSegment > step;
    final isCurrent = activeSegment == step;

    Color color;
    if (isDone) {
      color = const Color(0xFF10B981);
    } else if (isCurrent) {
      color = AppColors.primary;
    } else {
      color = Colors.white.withOpacity(0.2);
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? Colors.white : (isDone ? const Color(0xFF10B981) : Colors.white38),
            ),
          ),
        ],
      ),
    );
  }

  // ================= 4. DRAGGABLE TRACKING SHEET =================
  Widget _buildDraggableTrackingSheet(
    Color card,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.38,
      minChildSize: 0.22,
      maxChildSize: 0.90,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Sheet Grab Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // SECTION A: Shipper Profile Card
              _buildShipperProfileCard(card, textPrimary, textSecondary, border),
              const SizedBox(height: 12),

              // SECTION B: Quick Action Bar (Roommate Pickup & SOS KTX)
              _buildStudentQuickActionsBar(textPrimary, border),
              const SizedBox(height: 14),

              // SECTION C: Timeline Tiến trình Đơn ghép 2 Quán (Multi-Shop Custom Stepper)
              _buildMultiShopTimelineCard(textPrimary, textSecondary, border),
              const SizedBox(height: 14),

              // SECTION D: Thẻ Tóm tắt Đơn hàng Có thể Mở rộng (Expandable Order Summary)
              _buildExpandableOrderSummaryCard(textPrimary, textSecondary, border),
              const SizedBox(height: 14),

              // SECTION E: Badge Cam kết Bảo hiểm Bữa ăn KTX 100%
              _buildKtxMealInsuranceBadge(),
            ],
          ),
        );
      },
    );
  }

  // SECTION A: SHIPPER PROFILE CARD
  Widget _buildShipperProfileCard(
    Color card,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Shipper Avatar
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Shipper Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Trần Quốc Huy',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BK K21', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '4.95 (1.450+ chuyến KTX)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      'Wave Alpha đỏ • 59X3 - 688.92 (Áo cam KTX)',
                      style: TextStyle(fontSize: 11, color: textSecondary),
                    ),
                  ],
                ),
              ),

              // Action 1: Call Button
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF08HapticType.medium);
                  setState(() => _showCallingDialog = true);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                ),
              ),
              const SizedBox(width: 8),

              // Action 2: Chat Button
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF08HapticType.selection);
                  setState(() => _showChatSheet = true);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Chips 1-Chạm
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickMessageChip('Em đang xuống thang máy nè anh'),
                _buildQuickMessageChip('Để ở bàn bảo vệ giúp em'),
                _buildQuickMessageChip('Anh tới nơi nhá máy em nhé'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMessageChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          _sendChatMessage(text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi cho tài xế: "$text"'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_outlined, size: 11, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION B: STUDENT ACTIONS BAR
  Widget _buildStudentQuickActionsBar(Color textPrimary, Color border) {
    return Row(
      children: [
        // Button: Gửi bạn cùng phòng nhận hộ
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.group_rounded, size: 16),
            label: const Text(
              'Gửi Roommate nhận hộ',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              _triggerHaptic(_LF08HapticType.selection);
              setState(() => _showRoommateSheet = true);
            },
          ),
        ),
        const SizedBox(width: 8),

        // Button: Báo sự cố KTX
        InkWell(
          onTap: () {
            _triggerHaptic(_LF08HapticType.medium);
            setState(() => _showSosSheet = true);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF242426) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.report_problem_outlined, size: 15, color: Colors.orange),
                const SizedBox(width: 4),
                Text('Báo sự cố', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // SECTION C: TIMELINE TIẾN TRÌNH ĐƠN GHÉP 2 QUÁN
  Widget _buildMultiShopTimelineCard(Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF242426) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIẾN TRÌNH ĐƠN GHÉP 2 QUÁN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Gộp 1 Shipper', style: TextStyle(fontSize: 9.5, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Step 1: Đã nhận đơn ghép
          _buildMultiShopTimelineStep(
            time: '12:02',
            title: 'Đã nhận đơn ghép #LF-8924',
            detail: 'Tự động liên kết 2 quán gần nhau tại Khu B & thanh toán Ví LangFood Pay thành công.',
            isCompleted: true,
            isActive: false,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Step 2: Cả 2 quán đã nấu xong (Tách nhỏ 2 quán)
          _buildMultiShopTimelineStep(
            time: '12:08',
            title: 'Cả 2 quán đã nấu xong món',
            detail: '• 🍗 Cơm Gà Bà Tám xong lúc 12:06\n• 🧋 Trà Sữa Vân Nam xong lúc 12:08',
            isCompleted: _currentStage != LF08TrackingStage.preparing,
            isActive: _currentStage == LF08TrackingStage.preparing,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Step 3: Shipper đã lấy đủ 2 quán
          _buildMultiShopTimelineStep(
            time: '12:12',
            title: 'Shipper đã lấy đủ 2 quán',
            detail: 'Kiểm tra túi giữ nhiệt hai ngăn và bắt đầu di chuyển vào cổng KTX Khu B.',
            isCompleted: _currentStage == LF08TrackingStage.delivering || _currentStage == LF08TrackingStage.arrived,
            isActive: _currentStage == LF08TrackingStage.pickingUp,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Step 4: Shipper tới sảnh Tòa BA2 (Đang tới)
          _buildMultiShopTimelineStep(
            time: '12:25',
            title: 'Shipper tới sảnh Tòa BA2 (Đang tới)',
            detail: '🚀 Hệ thống tự động rung chuông trước 2 phút để sinh viên thong thả xuống sảnh.',
            isCompleted: _currentStage == LF08TrackingStage.arrived,
            isActive: _currentStage == LF08TrackingStage.delivering,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),

          // Step 5: Giao thành công
          _buildMultiShopTimelineStep(
            time: '12:28',
            title: 'Giao hàng thành công',
            detail: 'Nhận đồ ăn nóng hổi tại chân thang máy sảnh Tầng G Tòa BA2.',
            isCompleted: _currentStage == LF08TrackingStage.arrived,
            isActive: _currentStage == LF08TrackingStage.arrived,
            isLast: true,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiShopTimelineStep({
    required String time,
    required String title,
    required String detail,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    Color stepColor;
    if (isCompleted) {
      stepColor = const Color(0xFF10B981);
    } else if (isActive) {
      stepColor = AppColors.primary;
    } else {
      stepColor = Colors.grey.shade400;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Icon & Line
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : (isActive ? AppColors.primary : Colors.transparent),
                  shape: BoxShape.circle,
                  border: Border.all(color: stepColor, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                      : (isActive
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: isCompleted ? const Color(0xFF10B981) : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w600,
                          color: isActive ? AppColors.primary : textPrimary,
                        ),
                      ),
                      Text(time, style: TextStyle(fontSize: 10.5, color: textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(fontSize: 11, color: textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION D: EXPANDABLE ORDER SUMMARY CARD
  Widget _buildExpandableOrderSummaryCard(Color textPrimary, Color textSecondary, Color border) {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF242426) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          title: Text(
            'TÓM TẮT ĐƠN HÀNG (4 MÓN)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          subtitle: Text(
            'Tổng thanh toán: 96.000₫ (Ví LangFood Pay)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 12),

                  // Quán 1
                  Text('🍗 Quán 1 - Cơm Gà Da Giòn Bà Tám', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  _buildDishRow('1x Cơm Gà Xối Mỡ Da Giòn', '40.000₫', textPrimary, textSecondary),
                  _buildDishRow('1x Canh Rong Biển Thịt Bằm', '8.000₫', textPrimary, textSecondary),
                  Text('Ghi chú bếp: Ít mỡ, da giòn, thêm dưa leo', style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),

                  const Divider(height: 16),

                  // Quán 2
                  Text('🧋 Quán 2 - Trà Sữa Nướng Vân Nam KTX', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  _buildDishRow('1x Trà Sữa Nướng Vân Nam (Full Topping)', '38.000₫', textPrimary, textSecondary),
                  _buildDishRow('1x Bánh Tráng Cuộn Bơ Trứng Muối', '25.000₫', textPrimary, textSecondary),
                  Text('Ghi chú bếp: Để riêng đá, 50% đường, giao chung', style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),

                  const Divider(height: 16),

                  // Địa điểm giao & Breakdown
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tòa BA2, KTX Khu B ĐHQG • Sảnh Tầng G (Chân thang máy) • Phòng 512, Lầu 5',
                          style: TextStyle(fontSize: 11.5, color: textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Đã áp dụng voucher KTX: LANGFOODPAIR (-20k) & FREESHIP', style: TextStyle(fontSize: 10.5, color: Colors.green, fontWeight: FontWeight.bold)),
                        Text('Tiết kiệm 35k', style: TextStyle(fontSize: 10.5, color: Colors.green, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDishRow(String name, String price, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontSize: 12, color: textPrimary)),
          Text(price, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
        ],
      ),
    );
  }

  // SECTION E: BADGE BẢO HIỂM BỮA ĂN KTX 100%
  Widget _buildKtxMealInsuranceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cam kết Bảo hiểm bữa ăn KTX 100%',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                ),
                Text(
                  'Hoàn tiền trong 5 phút nếu món bị nguội ngắt hoặc đổ vỡ do vận chuyển.',
                  style: TextStyle(fontSize: 10.5, color: Colors.brown.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 5. IN-APP CHAT MODAL SHEET =================
  Widget _buildChatModal(
    Color card,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      top: 140,
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Chat Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trần Quốc Huy (BK K21)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const Text(
                          'Đang hoạt động • Wave Alpha 59X3 - 688.92',
                          style: TextStyle(fontSize: 11, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: textPrimary,
                    onPressed: () {
                      _triggerHaptic(_LF08HapticType.selection);
                      setState(() => _showChatSheet = false);
                    },
                  ),
                ],
              ),
            ),

            // Pre-canned Quick Student Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickChatChip('Em đang xuống thang máy nè anh'),
                    _buildQuickChatChip('Để ở bàn bảo vệ giúp em'),
                    _buildQuickChatChip('Anh tới nơi nhá máy em nhé'),
                  ],
                ),
              ),
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatMessages[index];
                  final isStudent = msg['sender'] == 'student';
                  final isSystem = msg['sender'] == 'system';

                  if (isSystem) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'] as String,
                          style: TextStyle(fontSize: 10.5, color: textSecondary),
                        ),
                      ),
                    );
                  }

                  return Align(
                    alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: isStudent ? AppColors.primary : (_isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isStudent ? 16 : 4),
                          bottomRight: Radius.circular(isStudent ? 4 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isStudent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isStudent ? Colors.white : textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            msg['time'] as String,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isStudent ? Colors.white.withOpacity(0.7) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              decoration: BoxDecoration(
                color: card,
                border: Border(top: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInputController,
                      style: TextStyle(fontSize: 13, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin cho tài xế Trần Quốc Huy...',
                        hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                        filled: true,
                        fillColor: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendChatMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _sendChatMessage(_chatInputController.text),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChatChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E22) : Colors.white,
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onPressed: () => _sendChatMessage(text),
      ),
    );
  }

  // ================= 6. PHONE CALL DIALOG =================
  Widget _buildCallDialog(Color card, Color textPrimary) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Đang gọi Trần Quốc Huy...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                const SizedBox(height: 4),
                const Text('0912 345 678 (Shipper KTX B - BK K21)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Cuộc gọi miễn phí qua ứng dụng LangFood Voice', style: TextStyle(fontSize: 11, color: Colors.green)),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        _triggerHaptic(_LF08HapticType.selection);
                        setState(() => _showCallingDialog = false);
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= 7. ROOMMATE PICKUP SHARE MODAL =================
  Widget _buildRoommateShareModal(
    Color card,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.group_rounded, color: Color(0xFF6366F1), size: 22),
                        SizedBox(width: 8),
                        Text('Nhờ Roommate Nhận Hộ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _showRoommateSheet = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Khi bận học bài, ôn thi hoặc đang trên giảng đường, hãy gửi mã PIN cho bạn cùng phòng để nhận đồ ăn nóng tại Sảnh Tầng G Tòa BA2.',
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
                ),
                const SizedBox(height: 16),

                // PIN Code Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'MÃ PIN NHẬN ĐỒ KTX',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6366F1), letterSpacing: 1),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _roommatePin,
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 6, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đọc mã này cho Shipper Huy (59X3 - 688.92)',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Copy Link Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Chia sẻ link Zalo / Messenger cho bạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      _triggerHaptic(_LF08HapticType.selection);
                      setState(() => _showRoommateSheet = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép liên kết nhận hộ kèm mã PIN: #PIN-7821'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF6366F1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= 8. SOS EMERGENCY REPORT MODAL =================
  Widget _buildSosReportModal(
    Color card,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emergency_rounded, color: Colors.red, size: 24),
                        SizedBox(width: 8),
                        Text('Hỗ Trợ Khẩn Cấp KTX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _showSosSheet = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn sự cố bạn đang gặp phải để đội ngũ hỗ trợ sinh viên LangFood can thiệp ngay trong 60 giây:',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 12),

                _buildSosOptionTile('Không gọi được tài xế quá 5 phút', Icons.phone_disabled_rounded),
                _buildSosOptionTile('Tài xế giao nhầm sảnh hoặc nhầm tòa KTX', Icons.wrong_location_rounded),
                _buildSosOptionTile('Món ăn bị đổ nước hoặc túi bị rách', Icons.soup_kitchen_outlined),
                _buildSosOptionTile('Cần gọi trực ban bảo vệ KTX Khu B (24/7)', Icons.local_police_rounded),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _showSosSheet = false),
                    child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSosOptionTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          _triggerHaptic(_LF08HapticType.medium);
          setState(() => _showSosSheet = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã báo cáo: "$title" - Nhân viên CSKH KTX đang gọi lại bạn!'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.red.shade700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade900),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn hình Chọn Vai Trò (Shipper hoặc Khách Hàng) để test
class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text("LangFood - Chọn Vai Trò Test"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fastfood, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                "LangFood Live Tracking",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 8),
              const Text(
                "Vui lòng chọn vai trò của thiết bị này:",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Nút Mở Giao diện Shipper
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.directions_bike, color: Colors.white, size: 28),
                  label: const Text(
                    "Tôi là Shipper (Giao Hàng)",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveTrackingScreen(isShipper: true),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Nút Mở Giao diện Khách Hàng
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person_pin_circle, color: Colors.white, size: 28),
                  label: const Text(
                    "Tôi là Khách Hàng (Đặt Đồ)",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveTrackingScreen(isShipper: false),
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
}
