import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../shipper/presentation/screens/shipper_orders_screen.dart';

/// Các trạng thái kết nối SignalR LocationHub mô phỏng
enum SignalRConnectionState {
  connected, // SignalR Live: Đang di chuyển bình thường (18ms)
  reconnecting, // Mất kết nối: Đang thử kết nối lại
  nearSanh, // Tới sảnh Tòa BA2 (Cách 100m - Rung chuông báo)
  completed, // Giao xong: Hoàn tất đơn hàng
}

/// Các chế độ bản đồ không watermark (Esri ArcGIS Base Layers)
enum LF09MapLayerType {
  streets, // Đường phố KTX ĐHQG
  dark, // Nền tối sang trọng (Không watermark)
  satellite, // Ảnh vệ tinh quang học ĐHQG
}

enum _LF09HapticType {
  light,
  medium,
  selection,
}

class SignalRLiveTrackingScreen extends StatefulWidget {
  final String orderCode;
  final String deliveryAddress;
  final LatLng? initialShipperPos;
  final LatLng? destinationPos;

  const SignalRLiveTrackingScreen({
    super.key,
    this.orderCode = '#LF-8924',
    this.deliveryAddress = 'Sảnh G • Tòa BA2, KTX Khu B ĐHQG TP.HCM (Phòng 512)',
    this.initialShipperPos,
    this.destinationPos,
  });

  @override
  State<SignalRLiveTrackingScreen> createState() => _SignalRLiveTrackingScreenState();
}

class _SignalRLiveTrackingScreenState extends State<SignalRLiveTrackingScreen>
    with TickerProviderStateMixin {
  // Map Controller
  final MapController _mapController = MapController();

  // KTX Khu B Campus Landmark Coordinates
  final LatLng _shop1Pos = const LatLng(10.8818, 106.8042); // Cơm Gà Bà Tám
  final LatLng _shop2Pos = const LatLng(10.8801, 106.8062); // Trà Sữa Vân Nam
  late LatLng _destinationPos; // Sảnh G Tòa BA2

  // Shipper GPS Tracking state
  late LatLng _currentShipperPos;
  double _shipperBearing = 48.0;
  double _currentSpeedKmH = 24.0;
  int _pingMs = 18;

  // SignalR & Screen UI states
  SignalRConnectionState _signalRState = SignalRConnectionState.connected;
  LF09MapLayerType _selectedMapType = LF09MapLayerType.streets;
  bool _isDarkMode = false;
  bool _showChatModal = false;
  bool _showCallModal = false;
  bool _showRoommateModal = false;
  bool _showSosModal = false;
  bool _showCompletionModal = false;

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _glowController;
  Timer? _locationHubSimulatorTimer;
  int _routeIndex = 4; // Start already after picking up from Shop 2

  // Route Coordinates
  late List<LatLng> _fullCampusRoute;
  List<LatLng> _traveledPath = [];
  List<LatLng> _remainingPath = [];

  // Metrics
  int _remainingDistanceM = 650;
  int _etaMinutes = 4;
  final String _deliveryEtaTime = '12:25';
  final String _securityOtp = '7821';

  // Chat message history
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'sender': 'system',
      'text': 'Đã kết nối SignalR LocationHub ĐHQG (Server TP.HCM • 18ms).',
      'time': '12:12',
    },
    {
      'sender': 'shipper',
      'text': 'Chào bạn Minh, mình đã lấy đủ 2 quán rồi nhé! Đang chạy qua đường Tạ Quang Bửu vào sảnh BA2 🛵',
      'time': '12:18',
    },
    {
      'sender': 'student',
      'text': 'Dạ em đợi ở sảnh G rồi nha anh Huy!',
      'time': '12:20',
    },
  ];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _destinationPos = widget.destinationPos ?? const LatLng(10.8828, 106.8080);
    _currentShipperPos = widget.initialShipperPos ?? const LatLng(10.8814, 106.8069);

    // Full Campus OSRM Route
    _fullCampusRoute = [
      _shop1Pos,
      const LatLng(10.8814, 106.8048),
      const LatLng(10.8807, 106.8055),
      _shop2Pos,
      const LatLng(10.8809, 106.8066), // Point 4: Corner of Tạ Quang Bửu
      const LatLng(10.8814, 106.8069), // Point 5: Running along Tạ Quang Bửu
      const LatLng(10.8820, 106.8074), // Point 6: Near KTX B2
      const LatLng(10.8824, 106.8077), // Point 7: Turning into BA2 gate
      _destinationPos, // Point 8: Sảnh G Tòa BA2
    ];

    _updatePathSegments();

    // Pulsing radar animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Polyline neon glow breath animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Simulated SignalR LocationHub periodic updates
    _startSignalRSimulation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _locationHubSimulatorTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  void _triggerHaptic([_LF09HapticType type = _LF09HapticType.light]) {
    try {
      if (type == _LF09HapticType.selection) {
        HapticFeedback.selectionClick();
      } else if (type == _LF09HapticType.medium) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void _updatePathSegments() {
    final idx = _routeIndex.clamp(0, _fullCampusRoute.length - 1);
    _traveledPath = _fullCampusRoute.sublist(0, idx + 1);
    _remainingPath = _fullCampusRoute.sublist(idx);
    if (_remainingPath.isNotEmpty) {
      _remainingPath[0] = _currentShipperPos; // anchor to live position
    }
  }

  void _startSignalRSimulation() {
    _locationHubSimulatorTimer?.cancel();
    _locationHubSimulatorTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_signalRState == SignalRConnectionState.connected) {
        setState(() {
          if (_routeIndex < _fullCampusRoute.length - 1) {
            _routeIndex++;
            final nextCoord = _fullCampusRoute[_routeIndex];
            _shipperBearing = _calculateBearing(_currentShipperPos, nextCoord);
            _currentShipperPos = nextCoord;

            // Fluctuate speed around 23 - 26 km/h
            _currentSpeedKmH = 23.5 + (math.Random().nextDouble() * 2.8);
            _pingMs = 15 + math.Random().nextInt(8);

            // Decrease remaining metrics
            _remainingDistanceM = math.max(60, _remainingDistanceM - 140);
            if (_remainingDistanceM <= 150 && _signalRState != SignalRConnectionState.nearSanh) {
              _triggerNearSanhAlert();
            }
            _updatePathSegments();
          } else {
            _remainingDistanceM = 0;
            _etaMinutes = 0;
            _currentSpeedKmH = 0.0;
          }
        });
      }
    });
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

  void _triggerNearSanhAlert() {
    _triggerHaptic(_LF09HapticType.medium);
    setState(() {
      _signalRState = SignalRConnectionState.nearSanh;
      _remainingDistanceM = 95;
      _etaMinutes = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.vibration_rounded, color: Colors.amber, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '🔔 Rung chuông: Shipper Trần Quốc Huy cách sảnh BA2 100m! Chuẩn bị xuống nhận món.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'ĐÃ HIỂU',
          textColor: AppColors.primary,
          onPressed: () {},
        ),
      ),
    );
  }

  void _setSignalRState(SignalRConnectionState state) {
    _triggerHaptic(_LF09HapticType.medium);
    setState(() {
      _signalRState = state;
      if (state == SignalRConnectionState.connected) {
        _routeIndex = 5;
        _currentShipperPos = _fullCampusRoute[_routeIndex];
        _currentSpeedKmH = 24.0;
        _remainingDistanceM = 480;
        _etaMinutes = 3;
        _updatePathSegments();
      } else if (state == SignalRConnectionState.reconnecting) {
        _currentSpeedKmH = 0.0;
        _pingMs = 999;
      } else if (state == SignalRConnectionState.nearSanh) {
        _routeIndex = 7;
        _currentShipperPos = _fullCampusRoute[_routeIndex];
        _remainingDistanceM = 95;
        _etaMinutes = 1;
        _currentSpeedKmH = 12.0;
        _updatePathSegments();
        _triggerNearSanhAlert();
      } else if (state == SignalRConnectionState.completed) {
        _routeIndex = 8;
        _currentShipperPos = LatLng(_destinationPos.latitude - 0.0003, _destinationPos.longitude - 0.0003);
        _remainingDistanceM = 0;
        _etaMinutes = 0;
        _currentSpeedKmH = 0.0;
        _updatePathSegments();
        _showOrderCompletedDialog();
      }
    });
  }

  void _showOrderCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 16),
              const Text(
                'Giao đơn thành công! 🎉',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Bạn đã nhận đủ 4 món ăn nóng hổi từ Cơm Gà Bà Tám & Trà Sữa Vân Nam tại sảnh BA2.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Rating row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text('Đánh giá 5⭐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.brown)),
                  ],
                ),
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
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (r) => false,
                    );
                  },
                  child: const Text('VỀ TRANG CHỦ LÀNG FOOD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Map Controls Action Methods
  void _fitRoute() {
    _triggerHaptic(_LF09HapticType.selection);
    _mapController.move(
      LatLng(
        (_currentShipperPos.latitude + _destinationPos.latitude) / 2,
        (_currentShipperPos.longitude + _destinationPos.longitude) / 2,
      ),
      16.2,
    );
  }

  void _snapToMyLocation() {
    _triggerHaptic(_LF09HapticType.selection);
    _mapController.move(_destinationPos, 17.0);
  }

  void _zoomIn() {
    _triggerHaptic(_LF09HapticType.selection);
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 0.6);
  }

  void _zoomOut() {
    _triggerHaptic(_LF09HapticType.selection);
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 0.6);
  }

  void _toggleMapLayer() {
    _triggerHaptic(_LF09HapticType.selection);
    setState(() {
      if (_selectedMapType == LF09MapLayerType.streets) {
        _selectedMapType = LF09MapLayerType.dark;
        _isDarkMode = true;
      } else if (_selectedMapType == LF09MapLayerType.dark) {
        _selectedMapType = LF09MapLayerType.satellite;
      } else {
        _selectedMapType = LF09MapLayerType.streets;
        _isDarkMode = false;
      }
    });
  }

  String _getMapTileUrl() {
    switch (_selectedMapType) {
      case LF09MapLayerType.dark:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
      case LF09MapLayerType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case LF09MapLayerType.streets:
      default:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  void _sendChatMessage(String text) {
    if (text.trim().isEmpty) return;
    _triggerHaptic(_LF09HapticType.light);
    setState(() {
      _chatMessages.add({
        'sender': 'student',
        'text': text.trim(),
        'time': 'Vừa xong',
      });
      _chatController.clear();
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _chatMessages.add({
          'sender': 'shipper',
          'text': 'Anh nghe nè Minh ơi! Đang quẹo vào cổng bảo vệ sảnh BA2 rồi nhé 👍',
          'time': 'Vừa xong',
        });
      });
      _triggerHaptic(_LF09HapticType.selection);
    });
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
          // 1. Fullscreen OSRM Campus Vector Map (100% Watermark-free)
          _buildCampusMap(),

          // 2. Top Bar: SignalR LocationHub Indicator & Inspector
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInspectorSwitcherBar(themeCard, themeTextPrimary, themeBorder),
                const SizedBox(height: 8),
                _buildSignalRHubPill(themeCard, themeTextPrimary, themeBorder),
                const SizedBox(height: 8),
                _buildFloatingEtaCard(),
              ],
            ),
          ),

          // 3. Frosted Glass Map Control Cluster (Apple HIG)
          Positioned(
            right: 16,
            bottom: 270,
            child: _buildFrostedMapControls(themeCard, themeTextPrimary, themeBorder),
          ),

          // 4. Draggable Bottom Sheet 3-Detents (18%, 45%, 88%)
          _buildDraggableBottomSheet(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),

          // 5. In-App Quick Chat Modal
          if (_showChatModal)
            _buildChatModal(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),

          // 6. Voice Call Modal
          if (_showCallModal)
            _buildCallModal(themeCard, themeTextPrimary),

          // 7. Roommate Pickup Share Modal
          if (_showRoommateModal)
            _buildRoommateModal(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),

          // 8. SOS Emergency Sheet
          if (_showSosModal)
            _buildSosModal(themeCard, themeTextPrimary, themeTextSecondary, themeBorder),
        ],
      ),
    );
  }

  // ================= 1. FULLSCREEN CAMPUS MAP =================
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
        // Watermark-Free Esri Base Layer
        TileLayer(
          urlTemplate: _getMapTileUrl(),
          userAgentPackageName: 'vn.langfood.campus',
        ),

        // Dual Glowing Polyline Layer (Traveled Path & Active Glow Path)
        PolylineLayer(
          polylines: [
            // 1. Traveled Path (Subtle dashed pastel orange/gray)
            if (_traveledPath.length >= 2)
              Polyline(
                points: _traveledPath,
                strokeWidth: 4.5,
                color: Colors.orange.withOpacity(0.35),
                isDotted: true,
              ),

            // 2. Active Glow Path (Outer halo)
            if (_remainingPath.length >= 2)
              Polyline(
                points: _remainingPath,
                strokeWidth: 9.0,
                color: AppColors.primary.withOpacity(0.28),
              ),

            // 3. Active Glow Path (Bright neon orange core)
            if (_remainingPath.length >= 2)
              Polyline(
                points: _remainingPath,
                strokeWidth: 5.5,
                color: const Color(0xFFFF5722),
                borderColor: Colors.white,
                borderStrokeWidth: 1.5,
              ),
          ],
        ),

        // Markers Layer
        MarkerLayer(
          markers: [
            // Quán 1: Cơm Gà Bà Tám
            Marker(
              point: _shop1Pos,
              width: 110,
              height: 55,
              alignment: Alignment.topCenter,
              child: _buildPoiBadge('🍗', 'Cơm Bà Tám', 'Quán 1'),
            ),

            // Quán 2: Trà Sữa Vân Nam
            Marker(
              point: _shop2Pos,
              width: 120,
              height: 55,
              alignment: Alignment.topCenter,
              child: _buildPoiBadge('🧋', 'Trà Sữa Vân Nam', 'Quán 2'),
            ),

            // Destination Pin: Sảnh G • Tòa Nhà BA2, KTX Khu B
            Marker(
              point: _destinationPos,
              width: 140,
              height: 70,
              alignment: Alignment.topCenter,
              child: _buildDestinationPin(),
            ),

            // Animated Moving Shipper Marker (Wave Alpha + Radar Ring + Speed)
            Marker(
              point: _currentShipperPos,
              width: 120,
              height: 85,
              alignment: Alignment.center,
              child: _buildAnimatedShipperMarker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPoiBadge(String emoji, String title, String sub) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFC2410C)),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 14))),
        ),
      ],
    );
  }

  Widget _buildDestinationPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_rounded, size: 11, color: Colors.white),
              SizedBox(width: 3),
              Text(
                'Sảnh G • BA2 KTX B',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
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
          child: const Icon(Icons.apartment_rounded, color: Color(0xFF10B981), size: 17),
        ),
      ],
    );
  }

  Widget _buildAnimatedShipperMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.38);
        final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label with Shipper name & speed
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'Quốc Huy • ${_currentSpeedKmH.toStringAsFixed(0)} km/h',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(height: 3),

            // Pulsing radar ripple ring & motorcycle icon
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(opacity * 0.45),
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.two_wheeler_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ================= 2. TOP SIGNALR LOCATIONHUB BAR =================
  Widget _buildInspectorSwitcherBar(Color card, Color textPrimary, Color border) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.hub_rounded, size: 14, color: Color(0xFF38BDF8)),
            const SizedBox(width: 5),
            const Text(
              'LF-09 SignalR:',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),

            _buildStateChip(SignalRConnectionState.connected, '1. Live 24km/h', Icons.wifi_tethering_rounded, Colors.green),
            const SizedBox(width: 5),
            _buildStateChip(SignalRConnectionState.reconnecting, '2. Mất mạng', Icons.wifi_off_rounded, Colors.amber),
            const SizedBox(width: 5),
            _buildStateChip(SignalRConnectionState.nearSanh, '3. Tới 100m', Icons.notifications_active_rounded, Colors.deepOrange),
            const SizedBox(width: 5),
            _buildStateChip(SignalRConnectionState.completed, '4. Giao xong', Icons.check_circle_rounded, Colors.blue),
            const SizedBox(width: 8),

            // Dark Mode toggle
            InkWell(
              onTap: () {
                _triggerHaptic(_LF09HapticType.selection);
                setState(() {
                  _isDarkMode = !_isDarkMode;
                  _selectedMapType = _isDarkMode ? LF09MapLayerType.dark : LF09MapLayerType.streets;
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
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.amber : Colors.white),
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

  Widget _buildStateChip(SignalRConnectionState state, String label, IconData icon, Color color) {
    final isSelected = _signalRState == state;
    return InkWell(
      onTap: () => _setSignalRState(state),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white.withOpacity(0.12),
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

  Widget _buildSignalRHubPill(Color card, Color textPrimary, Color border) {
    Color indicatorColor;
    String statusText;

    switch (_signalRState) {
      case SignalRConnectionState.connected:
        indicatorColor = const Color(0xFF10B981);
        statusText = 'SignalR: Connected (${_pingMs}ms) • LocationHub ĐHQG';
        break;
      case SignalRConnectionState.reconnecting:
        indicatorColor = Colors.amber;
        statusText = 'SignalR: Đang kết nối lại... (Thử lại sau 3s)';
        break;
      case SignalRConnectionState.nearSanh:
        indicatorColor = Colors.deepOrange;
        statusText = 'SignalR: Gần tới sảnh BA2 (Cách 95m • Rung chuông)';
        break;
      case SignalRConnectionState.completed:
        indicatorColor = Colors.blue;
        statusText = 'SignalR: Hoàn tất đơn hàng #LF-8924';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: card.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              // Back Button (Returns to Shipper Screen if Shipper, or Home if Student)
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF09HapticType.selection);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final isShipperRole = authProvider.user?.isShipper ?? false;
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
                      (r) => false,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: textPrimary),
                ),
              ),
              const SizedBox(width: 10),

              // SignalR Indicator Dot
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: indicatorColor.withOpacity(0.6), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // SOS Button
              InkWell(
                onTap: () {
                  _triggerHaptic(_LF09HapticType.medium);
                  setState(() => _showSosModal = true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emergency_rounded, size: 12, color: Colors.red),
                      SizedBox(width: 3),
                      Text('SOS KTX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
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

  // Floating ETA & Distance Pill
  Widget _buildFloatingEtaCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 15, color: Color(0xFF38BDF8)),
          const SizedBox(width: 6),
          Text(
            _signalRState == SignalRConnectionState.completed
                ? 'Đã giao tới Sảnh G BA2'
                : 'Còn $_remainingDistanceM m • ~$_etaMinutes phút (Dự kiến đến $_deliveryEtaTime)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= 3. FROSTED GLASS MAP CONTROLS =================
  Widget _buildFrostedMapControls(Color card, Color textPrimary, Color border) {
    return Column(
      children: [
        // 1. Fit Route Button
        _buildFrostedControlButton(
          icon: Icons.route_rounded,
          color: const Color(0xFF2563EB),
          onTap: _fitRoute,
          tooltip: 'Fit Route',
          card: card,
          border: border,
        ),
        const SizedBox(height: 8),

        // 2. Compass / Bearing Heading
        _buildFrostedControlButton(
          icon: Icons.explore_rounded,
          color: Colors.deepOrange,
          onTap: () {
            _triggerHaptic(_LF09HapticType.selection);
            _mapController.rotate(_shipperBearing);
          },
          tooltip: 'Compass',
          card: card,
          border: border,
        ),
        const SizedBox(height: 8),

        // 3. Snap to My Location (Destination BA2)
        _buildFrostedControlButton(
          icon: Icons.my_location_rounded,
          color: const Color(0xFF10B981),
          onTap: _snapToMyLocation,
          tooltip: 'Vị trí của tôi',
          card: card,
          border: border,
        ),
        const SizedBox(height: 8),

        // 4. Map Layer Switcher
        _buildFrostedControlButton(
          icon: Icons.layers_rounded,
          color: Colors.purple,
          onTap: _toggleMapLayer,
          tooltip: 'Đổi kiểu bản đồ',
          card: card,
          border: border,
        ),
        const SizedBox(height: 8),

        // 5. Zoom Pair [ + / - ]
        Container(
          decoration: BoxDecoration(
            color: card.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: _zoomIn,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.add_rounded, size: 20, color: textPrimary),
                ),
              ),
              Divider(height: 1, color: border),
              InkWell(
                onTap: _zoomOut,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.remove_rounded, size: 20, color: textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrostedControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
    required Color card,
    required Color border,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: card.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ================= 4. DRAGGABLE BOTTOM SHEET (3 DETENTS) =================
  Widget _buildDraggableBottomSheet(
    Color card,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45, // 45% Standard
      minChildSize: 0.18, // 18% Collapsed
      maxChildSize: 0.88, // 88% Expanded
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 22,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Grab Handle
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
              const SizedBox(height: 10),

              // PART 1: 18% Collapsed Row (Always visible)
              _buildCollapsedHeaderRow(textPrimary, textSecondary),
              const SizedBox(height: 12),

              // PART 2: 45% Standard Section
              // Banner nhắc nhở chuẩn bị xuống sảnh G
              _buildArrivalReminderBanner(),
              const SizedBox(height: 12),

              // Thẻ tài xế sinh viên Trần Quốc Huy
              _buildShipperCard(card, textPrimary, textSecondary, border),
              const SizedBox(height: 12),

              // Phím hành động nhanh (Gửi tin nhắn 1-chạm & Nhờ Roommate nhận hộ)
              _buildQuickActionsRow(textPrimary, border),
              const SizedBox(height: 16),

              // PART 3: 88% Expanded Section (Danh sách 4 món & mã PIN)
              _buildExpandedOrderSection(textPrimary, textSecondary, border),
            ],
          ),
        );
      },
    );
  }

  // 18% Collapsed Row
  Widget _buildCollapsedHeaderRow(Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.moped_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Dự kiến đến $_deliveryEtaTime',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Còn ~$_etaMinutes phút', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ],
              ),
              Text(
                'Sảnh Tầng G • Tòa BA2 KTX Khu B • Đơn ghép 2 quán',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
        ),

        // Quick Call Button
        InkWell(
          onTap: () {
            _triggerHaptic(_LF09HapticType.medium);
            setState(() => _showCallModal = true);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_rounded, color: Colors.green, size: 19),
          ),
        ),
      ],
    );
  }

  // Arrival Reminder Banner (100m Alert)
  Widget _buildArrivalReminderBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.vibration_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuẩn bị xuống sảnh Tòa BA2',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown.shade900),
                ),
                Text(
                  'Điện thoại sẽ rung và thông báo khi tài xế cách sảnh 100m. Vui lòng mang theo điện thoại để đọc OTP: $_securityOtp.',
                  style: TextStyle(fontSize: 10.5, color: Colors.brown.shade700, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shipper Profile Card
  Widget _buildShipperCard(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Trần Quốc Huy',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Bách Khoa K21', style: TextStyle(fontSize: 9.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text('4.95 (1.450+)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary)),
                    const SizedBox(width: 6),
                    Text('• Wave Đỏ 59X3-688.92', style: TextStyle(fontSize: 11, color: textSecondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Đã xác minh thẻ SV ✅', style: TextStyle(fontSize: 9.5, color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Message Button
          InkWell(
            onTap: () {
              _triggerHaptic(_LF09HapticType.selection);
              setState(() => _showChatModal = true);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Buttons
  Widget _buildQuickActionsRow(Color textPrimary, Color border) {
    return Column(
      children: [
        // Quick 1-tap message chip
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickMessageChip('Em đợi ở sảnh G rồi!'),
              _buildQuickMessageChip('Anh tới nơi nhá máy em nhé'),
              _buildQuickMessageChip('Để ở bàn bảo vệ giúp em'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Action Buttons Row
        Row(
          children: [
            // Button: Gửi bạn cùng phòng nhận hộ
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.group_rounded, size: 16),
                label: const Text(
                  'Bạn cùng phòng nhận hộ',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  _triggerHaptic(_LF09HapticType.selection);
                  setState(() => _showRoommateModal = true);
                },
              ),
            ),
            const SizedBox(width: 8),

            // Button: Chia sẻ lộ trình Zalo / Messenger
            InkWell(
              onTap: () {
                _triggerHaptic(_LF09HapticType.selection);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép liên kết lộ trình đơn hàng #LF-8924'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: _isDarkMode ? const Color(0xFF242426) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.share_outlined, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text('Chia sẻ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickMessageChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
        backgroundColor: _isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onPressed: () {
          _sendChatMessage(text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi cho tài xế: "$text"'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  // 88% Expanded Section: 4-Item List & Security PIN
  Widget _buildExpandedOrderSection(Color textPrimary, Color textSecondary, Color border) {
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
                'DANH SÁCH MÓN ĂN (4 MÓN)',
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
                child: const Text('Đã thanh toán 96k', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quán 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🍗 Quán 1 - Cơm Gà Da Giòn Bà Tám', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary)),
              const Text('Xong 12:06 ✅', style: TextStyle(fontSize: 10.5, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          _buildOrderItemRow('1x Cơm Gà Xối Mỡ Da Giòn', '40.000₫', textPrimary, textSecondary),
          _buildOrderItemRow('1x Canh Rong Biển Thịt Bằm', '8.000₫', textPrimary, textSecondary),

          const Divider(height: 16),

          // Quán 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🧋 Quán 2 - Trà Sữa Nướng Vân Nam KTX', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary)),
              const Text('Xong 12:08 ✅', style: TextStyle(fontSize: 10.5, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          _buildOrderItemRow('1x Trà Sữa Nướng Vân Nam (Full Topping)', '38.000₫', textPrimary, textSecondary),
          _buildOrderItemRow('1x Bánh Tráng Cuộn Bơ Trứng Muối', '25.000₫', textPrimary, textSecondary),

          const Divider(height: 16),

          // OTP Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MÃ BẢO MẬT ĐƠN HÀNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text(widget.orderCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('MÃ OTP GIAO NHẬN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                    Text(_securityOtp, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF1E3A8A))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(String name, String price, Color textPrimary, Color textSecondary) {
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

  // ================= 5. CHAT MODAL SHEET =================
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trần Quốc Huy (BK K21)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                        const Text('Đang chạy xe • Wave 59X3-688.92', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _showChatModal = false),
                  ),
                ],
              ),
            ),

            // Messages
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
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(msg['text'] as String, style: TextStyle(fontSize: 10.5, color: textSecondary)),
                      ),
                    );
                  }

                  return Align(
                    alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 270),
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
                          Text(msg['text'] as String, style: TextStyle(fontSize: 13, color: isStudent ? Colors.white : textPrimary)),
                          const SizedBox(height: 2),
                          Text(msg['time'] as String, style: TextStyle(fontSize: 9.5, color: isStudent ? Colors.white60 : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
              decoration: BoxDecoration(color: card, border: Border(top: BorderSide(color: border))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(fontSize: 13, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Nhắn cho tài xế Trần Quốc Huy...',
                        hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                        filled: true,
                        fillColor: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                      onSubmitted: _sendChatMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _sendChatMessage(_chatController.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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

  // ================= 6. VOICE CALL MODAL =================
  Widget _buildCallModal(Color card, Color textPrimary) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(28)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'),
                ),
                const SizedBox(height: 14),
                Text('Đang gọi Trần Quốc Huy...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 4),
                const Text('0912 345 678 (Shipper KTX B - BK K21)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => setState(() => _showCallModal = false),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= 7. ROOMMATE SHARE MODAL =================
  Widget _buildRoommateModal(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(28)),
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
                      onPressed: () => setState(() => _showRoommateModal = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gửi mã PIN này cho bạn cùng phòng để xuống chân thang máy Sảnh G nhận đồ ăn nóng giúp bạn.',
                  style: TextStyle(fontSize: 12, color: textSecondary, height: 1.35),
                ),
                const SizedBox(height: 16),
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
                      const Text('MÃ PIN NHẬN HÀNG KTX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                      const SizedBox(height: 6),
                      Text(_securityOtp, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 6, color: Color(0xFF4F46E5))),
                      const SizedBox(height: 4),
                      Text('Đọc mã này cho tài xế Trần Quốc Huy', style: TextStyle(fontSize: 11, color: textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Chia sẻ link Zalo / Messenger cho bạn', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      _triggerHaptic(_LF09HapticType.selection);
                      setState(() => _showRoommateModal = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép link nhận hộ kèm mã OTP: 7821')),
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

  // ================= 8. SOS EMERGENCY MODAL =================
  Widget _buildSosModal(Color card, Color textPrimary, Color textSecondary, Color border) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(28)),
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
                      onPressed: () => setState(() => _showSosModal = false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Chọn sự cố khẩn cấp để nhân viên CSKH LangFood xử lý ngay:', style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(height: 12),

                _buildSosOptionTile('Không liên lạc được tài xế quá 5 phút', Icons.phone_disabled_rounded),
                _buildSosOptionTile('Tài xế giao nhầm sảnh hoặc nhầm tòa KTX', Icons.wrong_location_rounded),
                _buildSosOptionTile('Món ăn bị đổ nước hoặc bị nguội', Icons.soup_kitchen_outlined),
                _buildSosOptionTile('Gọi trực ban bảo vệ KTX Khu B (24/7)', Icons.local_police_rounded),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _showSosModal = false),
                    child: const Text('Đóng'),
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
          _triggerHaptic(_LF09HapticType.medium);
          setState(() => _showSosModal = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã báo cáo: "$title" - Đang kết nối CSKH!'), backgroundColor: Colors.red.shade700),
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
              Expanded(child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade900))),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
