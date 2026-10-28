import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../restaurant/presentation/screens/restaurant_menu_screen.dart';

enum LF06MapState {
  normal, // Bản đồ KTX (Chuẩn)
  locating, // Đang định vị GPS
  error, // Lỗi GPS / Mất mạng
}

enum HandoverMethod {
  lobbyG, // Sảnh tầng G (Chân thang máy) - Miễn phí
  securityGate, // Cổng bảo vệ tòa nhà - Miễn phí
  doorRoom, // Giao tận cửa phòng KTX (+5.000₫)
}

enum _LF06HapticType {
  light,
  medium,
  selection,
}

class LocationPickerScreen extends StatefulWidget {
  final VoidCallback? onLocationSelected;

  const LocationPickerScreen({
    super.key,
    this.onLocationSelected,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with TickerProviderStateMixin {
  // Map Controller & Coords for KTX ĐHQG TP.HCM
  final MapController _mapController = MapController();

  // Tâm KTX Khu B ĐHQG: Tòa BA2
  static const LatLng _ktxKhuB_BA2 = LatLng(10.8805, 106.8048);
  static const LatLng _ktxKhuA_A15 = LatLng(10.8752, 106.7995);
  static const LatLng _thuVienTrungTam = LatLng(10.8700, 106.8030);
  static const LatLng _bachKhoaCS2 = LatLng(10.8812, 106.8075);
  static const LatLng _uitCS2 = LatLng(10.8702, 106.8021);

  LatLng _currentCenter = _ktxKhuB_BA2;
  double _currentZoom = 16.5;
  bool _is3DMode = false;

  // Search & Handover Details
  final TextEditingController _searchController =
      TextEditingController(text: 'Tòa BA2, KTX Khu B ĐHQG TP.HCM');
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _roomController =
      TextEditingController(text: 'Phòng 512, Lầu 5');

  HandoverMethod _selectedHandover = HandoverMethod.lobbyG;
  int _selectedCampusIndex = 0; // 0: KTX Khu B, 1: KTX Khu A, 2: Thư viện, 3: Bách Khoa, 4: UIT
  int _selectedSavedAddressIndex = 0; // 0: Phòng KTX, 1: Giảng đường H6, 2: Thư viện

  // UI Inspector states
  LF06MapState _mapState = LF06MapState.normal;
  bool _isDarkMode = false;
  bool _showHigOverlay = false;
  bool _isMapDragging = false;

  // Pin bouncing animation
  late AnimationController _pinAnimController;
  late Animation<double> _pinBounceAnimation;
  late AnimationController _pulseAnimController;

  // Campus clusters definition
  final List<Map<String, dynamic>> _campusClusters = [
    {
      'name': 'KTX Khu B (BA2)',
      'coords': _ktxKhuB_BA2,
      'address': 'Sảnh Tòa BA2, KTX Khu B ĐHQG',
      'detail': 'Chân thang máy sảnh chính',
      'tag': 'Tòa nhà bạn đang ở',
    },
    {
      'name': 'KTX Khu A (A15)',
      'coords': _ktxKhuA_A15,
      'address': 'Sảnh Tòa A15, KTX Khu A ĐHQG',
      'detail': 'Cổng đối diện nhà xe A15',
      'tag': 'Khu A',
    },
    {
      'name': 'Thư viện Trung tâm',
      'coords': _thuVienTrungTam,
      'address': 'Thư viện Trung tâm ĐHQG TP.HCM',
      'detail': 'Bàn đá sảnh tự học ngoài trời',
      'tag': 'Học nhóm',
    },
    {
      'name': 'ĐH Bách Khoa CS2',
      'coords': _bachKhoaCS2,
      'address': 'Tòa H6, Trường ĐH Bách Khoa CS2',
      'detail': 'Hành lang sảnh H6',
      'tag': 'Giảng đường',
    },
    {
      'name': 'ĐH CNTT (UIT)',
      'coords': _uitCS2,
      'address': 'Tòa A, Trường ĐH Công Nghệ Thông Tin',
      'detail': 'Cổng chính sảnh A',
      'tag': 'Trường UIT',
    },
  ];

  // Saved Favorite Addresses
  final List<Map<String, dynamic>> _savedAddresses = [
    {
      'icon': Icons.home_rounded,
      'title': 'Phòng KTX (Mặc định)',
      'address': 'Tòa BA2, P.512 • KTX Khu B',
      'handover': HandoverMethod.doorRoom,
    },
    {
      'icon': Icons.school_rounded,
      'title': 'Giảng đường H6',
      'address': 'Lầu 2 Tòa H6 • ĐH Bách Khoa CS2',
      'handover': HandoverMethod.lobbyG,
    },
    {
      'icon': Icons.local_library_rounded,
      'title': 'Thư viện Trung tâm',
      'address': 'Phòng tự học lầu 2 • ĐHQG TP.HCM',
      'handover': HandoverMethod.lobbyG,
    },
  ];

  // Quick delivery note tags
  final List<String> _quickNoteTags = [
    'Gọi trước 2p',
    'Để bàn giao đồ',
    'Gửi bảo vệ',
    'Nhắn tin Zalo',
    'Thang máy đang bảo trì',
  ];

  @override
  void initState() {
    super.initState();
    // Pin bounce animation
    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pinBounceAnimation = Tween<double>(begin: 0.0, end: -14.0).animate(
      CurvedAnimation(parent: _pinAnimController, curve: Curves.easeOutBack),
    );

    // Pulse animation for GPS
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _noteController.dispose();
    _roomController.dispose();
    _pinAnimController.dispose();
    _pulseAnimController.dispose();
    super.dispose();
  }

  void _triggerHaptic([_LF06HapticType type = _LF06HapticType.light]) {
    try {
      if (type == _LF06HapticType.selection) {
        HapticFeedback.selectionClick();
      } else if (type == _LF06HapticType.medium) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  void _animateToCoords(LatLng coords, [double zoom = 16.5]) {
    _triggerHaptic(_LF06HapticType.medium);
    setState(() {
      _currentCenter = coords;
      _currentZoom = zoom;
    });
    _mapController.move(coords, zoom);
  }

  void _selectCampusCluster(int index) {
    _triggerHaptic(_LF06HapticType.selection);
    setState(() {
      _selectedCampusIndex = index;
      final cluster = _campusClusters[index];
      _searchController.text = cluster['address'] as String;
    });
    _animateToCoords(_campusClusters[index]['coords'] as LatLng, 16.8);
  }

  Future<void> _handleGpsLocate() async {
    _triggerHaptic(_LF06HapticType.medium);
    setState(() => _mapState = LF06MapState.locating);

    // Simulate real GPS lock within 600ms
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    setState(() {
      _mapState = LF06MapState.normal;
      _selectedCampusIndex = 0;
      _searchController.text = 'Tòa BA2, KTX Khu B ĐHQG (GPS Độ chính xác cao ±3m)';
    });
    _animateToCoords(_ktxKhuB_BA2, 17.2);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Đã định vị chính xác: Sảnh Tòa BA2 KTX Khu B!'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggle3DMode() {
    _triggerHaptic(_LF06HapticType.selection);
    setState(() => _is3DMode = !_is3DMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_is3DMode ? 'Chế độ góc nhìn 3D Campus Mode kích hoạt' : 'Chế độ bản đồ 2D chuẩn kích hoạt'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _confirmDeliveryAddress() {
    _triggerHaptic(_LF06HapticType.medium);

    String finalAddress = _searchController.text.trim();
    if (_selectedHandover == HandoverMethod.doorRoom) {
      finalAddress += ' • ${_roomController.text.trim()} (+5k)';
    } else if (_selectedHandover == HandoverMethod.securityGate) {
      finalAddress += ' • Gửi Cổng bảo vệ tòa';
    } else {
      finalAddress += ' • Sảnh Tầng G (Chân thang máy)';
    }

    if (_noteController.text.trim().isNotEmpty) {
      finalAddress += ' (Ghi chú: ${_noteController.text.trim()})';
    }

    widget.onLocationSelected?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã chốt điểm giao: $finalAddress',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context, finalAddress);
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = _isDarkMode ? const Color(0xFF121214) : Colors.white;
    final themeSurface = _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final themeTextPrimary = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final themeTextSecondary = _isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF64748B);
    final themeBorder = _isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: themeBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ================= 1. FULLSCREEN CAMPUS MAP =================
            Positioned.fill(
              child: _buildCampusMapCanvas(),
            ),

            // ================= 2. DYNAMIC CENTER-PIN MARKER =================
            _buildCenterPinMarker(),

            // ================= 3. TOP INSPECTOR & SEARCH CONTROLLER =================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  _buildTopInspectorBar(themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),
                  _buildSearchAppBar(themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),
                ],
              ),
            ),

            // ================= 4. FLOATING FROSTED GLASS MAP CONTROLS =================
            Positioned(
              right: 16,
              bottom: 330,
              child: _buildFrostedMapControls(themeSurface, themeTextPrimary, themeBorder),
            ),

            // ================= 5. DRAGGABLE BOTTOM SHEET (HANDOVER & DETAILS) =================
            _buildDraggableBottomSheet(themeSurface, themeTextPrimary, themeTextSecondary, themeBorder),

            // ================= 6. HIG SPECS OVERLAY =================
            if (_showHigOverlay) _buildHigSpecsOverlay(),
          ],
        ),
      ),
    );
  }

  // ================= 1. FULLSCREEN CAMPUS MAP CANVAS =================
  Widget _buildCampusMapCanvas() {
    Widget mapContent = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter,
        initialZoom: _currentZoom,
        minZoom: 14.0,
        maxZoom: 18.5,
        onPositionChanged: (pos, hasGesture) {
          if (hasGesture) {
            if (!_isMapDragging) {
              setState(() => _isMapDragging = true);
              _pinAnimController.forward();
            }
            if (pos.center != null) {
              _currentCenter = pos.center!;
            }
          }
        },
        onPointerUp: (event, point) {
          if (_isMapDragging) {
            setState(() => _isMapDragging = false);
            _pinAnimController.reverse();
          }
        },
      ),
      children: [
        // Tile Layer: ArcGIS Street Map / OpenStreetMap
        TileLayer(
          urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'vn.langfood.campus',
        ),

        // Campus Delivery Safe Zone Circle (Vòng tròn giao hàng KTX)
        CircleLayer(
          circles: [
            CircleMarker(
              point: _ktxKhuB_BA2,
              radius: 450,
              useRadiusInMeter: true,
              color: AppColors.primary.withOpacity(0.08),
              borderColor: AppColors.primary.withOpacity(0.4),
              borderStrokeWidth: 2,
            ),
            CircleMarker(
              point: _ktxKhuA_A15,
              radius: 400,
              useRadiusInMeter: true,
              color: Colors.blue.withOpacity(0.08),
              borderColor: Colors.blue.withOpacity(0.35),
              borderStrokeWidth: 2,
            ),
          ],
        ),

        // Partner Food Shops Markers on Campus
        MarkerLayer(
          markers: [
            // Quán 1: Cơm Gà Bà Tám
            Marker(
              point: const LatLng(10.8818, 106.8042),
              width: 110,
              height: 48,
              child: _buildShopMapBadge('🍗 Cơm Gà Bà Tám', 'Cách 200m • 15p'),
            ),
            // Quán 2: Trà Sữa Vân Nam
            Marker(
              point: const LatLng(10.8801, 106.8062),
              width: 110,
              height: 48,
              child: _buildShopMapBadge('🧋 Trà Sữa Vân Nam', 'Tòa B4 • Mua 1 Tặng 1'),
            ),
            // Quán 3: Bún Đậu Phố Làng
            Marker(
              point: const LatLng(10.8785, 106.8035),
              width: 105,
              height: 48,
              child: _buildShopMapBadge('🍲 Bún Đậu Phố', 'Chợ đêm KTX B'),
            ),
          ],
        ),
      ],
    );

    // If 3D Mode is enabled, add perspective transform
    if (_is3DMode) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(0.25), // tilt forward
        child: mapContent,
      );
    }

    return mapContent;
  }

  Widget _buildShopMapBadge(String name, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(sub, style: const TextStyle(fontSize: 8.5, color: Colors.grey)),
        ],
      ),
    );
  }

  // ================= 2. DYNAMIC CENTER-PIN MARKER =================
  Widget _buildCenterPinMarker() {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _pinAnimController,
          builder: (context, child) {
            final bounceOffset = _pinBounceAnimation.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Callout Badge above marker
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        _campusClusters[_selectedCampusIndex]['detail'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Chuẩn KTX',
                          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Pin Icon with Vertical Bounce
                Transform.translate(
                  offset: Offset(0, bounceOffset),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.place_rounded, color: Colors.white, size: 28),
                  ),
                ),

                // Responsive Shadow Oval on Ground
                Container(
                  width: math.max(10.0, 24.0 + bounceOffset),
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Offset compensation for exact tip alignment
                const SizedBox(height: 38),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================= 3. TOP INSPECTOR & SEARCH APP BAR =================
  Widget _buildTopInspectorBar(Color surface, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: _isDarkMode ? const Color(0xFF1E1E22) : const Color(0xFF0F172A),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text(
              'LF-06 Campus Map:',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),

            // State: Normal
            _buildStateChip(LF06MapState.normal, 'Bản đồ KTX (Chuẩn)', Icons.check_circle_rounded, const Color(0xFF10B981)),
            const SizedBox(width: 6),

            // State: Locating GPS
            _buildStateChip(LF06MapState.locating, 'Đang định vị GPS', Icons.gps_fixed_rounded, const Color(0xFF6366F1)),
            const SizedBox(width: 6),

            // State: Error
            _buildStateChip(LF06MapState.error, 'Lỗi kết nối GPS', Icons.location_off_rounded, const Color(0xFFEF4444)),
            const SizedBox(width: 8),

            // Light / Dark mode
            InkWell(
              onTap: () {
                _triggerHaptic(_LF06HapticType.selection);
                setState(() => _isDarkMode = !_isDarkMode);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.amber.withOpacity(0.2) : Colors.indigo.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      size: 13,
                      color: _isDarkMode ? Colors.amber : Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isDarkMode ? 'Light' : 'Dark',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.amber : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // HIG Specs Overlay
            InkWell(
              onTap: () {
                _triggerHaptic(_LF06HapticType.selection);
                setState(() => _showHigOverlay = !_showHigOverlay);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showHigOverlay ? AppColors.primary : Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_on_rounded, size: 13, color: _showHigOverlay ? Colors.white : Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      'HIG Specs',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _showHigOverlay ? Colors.white : Colors.white70,
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

  Widget _buildStateChip(LF06MapState state, String label, IconData icon, Color color) {
    final isSelected = _mapState == state;
    return InkWell(
      onTap: () {
        _triggerHaptic(_LF06HapticType.selection);
        setState(() => _mapState = state);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAppBar(Color surface, Color textPrimary, Color textSecondary, Color border) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),

          // Search TextField
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm tòa KTX, giảng đường ĐHQG...',
                hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              ),
            ),
          ),

          // Clear button X
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.cancel_rounded, size: 18, color: textSecondary),
              onPressed: () {
                setState(() => _searchController.clear());
              },
            ),

          // Voice Search / Filter icon
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ================= 4. FLOATING FROSTED GLASS MAP CONTROLS =================
  Widget _buildFrostedMapControls(Color surface, Color textPrimary, Color border) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // GPS My Location
              IconButton(
                tooltip: 'Định vị GPS của tôi',
                icon: _mapState == LF06MapState.locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                onPressed: _handleGpsLocate,
              ),
              Divider(height: 1, color: border),

              // 3D / 2D Perspective Toggle
              IconButton(
                tooltip: _is3DMode ? 'Chuyển sang 2D' : 'Chuyển sang 3D Campus',
                icon: Icon(
                  _is3DMode ? Icons.view_in_ar_rounded : Icons.layers_outlined,
                  color: _is3DMode ? AppColors.primary : textPrimary,
                  size: 20,
                ),
                onPressed: _toggle3DMode,
              ),
              Divider(height: 1, color: border),

              // Zoom In [+]
              IconButton(
                tooltip: 'Phóng to',
                icon: Icon(Icons.add_rounded, color: textPrimary, size: 20),
                onPressed: () {
                  _triggerHaptic(_LF06HapticType.light);
                  setState(() => _currentZoom = math.min(18.5, _currentZoom + 0.6));
                  _mapController.move(_currentCenter, _currentZoom);
                },
              ),
              Divider(height: 1, color: border),

              // Zoom Out [-]
              IconButton(
                tooltip: 'Thu nhỏ',
                icon: Icon(Icons.remove_rounded, color: textPrimary, size: 20),
                onPressed: () {
                  _triggerHaptic(_LF06HapticType.light);
                  setState(() => _currentZoom = math.max(14.0, _currentZoom - 0.6));
                  _mapController.move(_currentCenter, _currentZoom);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 5. DRAGGABLE BOTTOM SHEET =================
  Widget _buildDraggableBottomSheet(
    Color surface,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.28,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Grab handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.white30 : Colors.black26,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // 2. Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                  children: [
                    // Header: Selected Building & Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _campusClusters[_selectedCampusIndex]['name'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                _campusClusters[_selectedCampusIndex]['address'] as String,
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '⚡ Freeship KTX',
                            style: TextStyle(fontSize: 10.5, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Campus Clusters Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_campusClusters.length, (idx) {
                          final cluster = _campusClusters[idx];
                          final isSelected = _selectedCampusIndex == idx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => _selectCampusCluster(idx),
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : border,
                                  ),
                                ),
                                child: Text(
                                  cluster['name'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Colors.white : textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION: 3 Phương thức bàn giao đặc thù KTX
                    Text(
                      'PHƯƠNG THỨC BÀN GIAO MÓN (ĐẶC THÙ KTX)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Option 1: Sảnh tầng G (Chân thang máy)
                    _buildHandoverOption(
                      method: HandoverMethod.lobbyG,
                      title: 'Sảnh tầng G (Chân thang máy)',
                      sub: 'Xuống nhận ngay khi shipper đến sảnh • Nhanh nhất',
                      priceText: 'Miễn phí',
                      badge: 'Khuyên dùng 🔥',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      border: border,
                    ),

                    // Option 2: Cổng bảo vệ tòa nhà
                    _buildHandoverOption(
                      method: HandoverMethod.securityGate,
                      title: 'Cổng bảo vệ tòa nhà',
                      sub: 'Gửi bác bảo vệ khi bạn đang bận học/thi cử',
                      priceText: 'Miễn phí',
                      badge: 'Tiện lợi',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      border: border,
                    ),

                    // Option 3: Giao tận cửa phòng KTX
                    _buildHandoverOption(
                      method: HandoverMethod.doorRoom,
                      title: 'Giao tận cửa phòng KTX',
                      sub: 'Shipper mang lên tận phòng (Phí hỗ trợ leo lầu)',
                      priceText: '+5.000₫',
                      badge: 'Tận phòng',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      border: border,
                    ),

                    // Extra field for Room if Giao tận phòng
                    if (_selectedHandover == HandoverMethod.doorRoom) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _roomController,
                        style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Số phòng & Tầng lầu',
                          labelStyle: TextStyle(fontSize: 12, color: textSecondary),
                          prefixIcon: const Icon(Icons.door_front_door_outlined, color: AppColors.primary, size: 18),
                          filled: true,
                          fillColor: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),

                    // SECTION: Saved Favorite Addresses
                    Text(
                      'ĐỊA CHỈ QUEN THUỘC ĐÃ LƯU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_savedAddresses.length, (idx) {
                        final saved = _savedAddresses[idx];
                        final isSelected = _selectedSavedAddressIndex == idx;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              _triggerHaptic(_LF06HapticType.selection);
                              setState(() {
                                _selectedSavedAddressIndex = idx;
                                _selectedHandover = saved['handover'] as HandoverMethod;
                                _searchController.text = saved['address'] as String;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              margin: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.08) : surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    saved['icon'] as IconData,
                                    size: 18,
                                    color: isSelected ? AppColors.primary : textSecondary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    saved['title'] as String,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    saved['address'] as String,
                                    style: TextStyle(fontSize: 10, color: textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),

                    // SECTION: Delivery Notes for Shipper
                    Text(
                      'GHI CHÚ CHO SHIPPER & GỢI Ý',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _quickNoteTags.map((tag) {
                        return InkWell(
                          onTap: () {
                            _triggerHaptic(_LF06HapticType.selection);
                            setState(() {
                              final cur = _noteController.text;
                              if (cur.isEmpty) {
                                _noteController.text = tag;
                              } else if (!cur.contains(tag)) {
                                _noteController.text = '$cur, $tag';
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(tag, style: TextStyle(fontSize: 11, color: textPrimary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      style: TextStyle(fontSize: 13, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Đến sảnh gọi mình xuống liền, đừng bấm chuông...',
                        hintStyle: TextStyle(fontSize: 12, color: textSecondary),
                        filled: true,
                        fillColor: _isDarkMode ? const Color(0xFF242426) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Sticky Bottom CTA Button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border(top: BorderSide(color: border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _confirmDeliveryAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'XÁC NHẬN ĐIỂM GIAO NÀY',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandoverOption({
    required HandoverMethod method,
    required String title,
    required String sub,
    required String priceText,
    required String badge,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final isSelected = _selectedHandover == method;
    return InkWell(
      onTap: () {
        _triggerHaptic(_LF06HapticType.selection);
        setState(() => _selectedHandover = method);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : border,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            Text(
              priceText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 6. HIG SPECS OVERLAY =================
  Widget _buildHigSpecsOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withOpacity(0.7), width: 2),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: Colors.red.withOpacity(0.85),
                child: const Text(
                  '📐 LF-06 HIG SPECS: Center-Pin Offset 38pt | DraggableSheet 0.28-0.85 | Grid 8pt | Radius 28pt',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: Colors.blue.withOpacity(0.85),
                child: const Text(
                  '🗺️ CAMPUS GEOLOCATION: KTX Khu B BA2 (10.8805, 106.8048) ➔ CartProvider.deliveryAddress',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
