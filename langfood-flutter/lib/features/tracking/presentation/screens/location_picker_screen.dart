import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../checkout/presentation/screens/checkout_screen.dart';

/// Mô hình cấu hình điểm giao hàng KTX
class CampusDeliveryLocation {
  final LatLng position;
  final String buildingName;
  final String subAddress;
  final String dropOffOptionKey; // 'g': Sảnh tầng G, 'gate': Cổng bảo vệ, 'door': Tận cửa phòng
  final String dropOffOptionLabel;
  final double extraFee;
  final String shipperNote;

  const CampusDeliveryLocation({
    required this.position,
    required this.buildingName,
    required this.subAddress,
    required this.dropOffOptionKey,
    required this.dropOffOptionLabel,
    this.extraFee = 0.0,
    this.shipperNote = '',
  });

  CampusDeliveryLocation copyWith({
    LatLng? position,
    String? buildingName,
    String? subAddress,
    String? dropOffOptionKey,
    String? dropOffOptionLabel,
    double? extraFee,
    String? shipperNote,
  }) {
    return CampusDeliveryLocation(
      position: position ?? this.position,
      buildingName: buildingName ?? this.buildingName,
      subAddress: subAddress ?? this.subAddress,
      dropOffOptionKey: dropOffOptionKey ?? this.dropOffOptionKey,
      dropOffOptionLabel: dropOffOptionLabel ?? this.dropOffOptionLabel,
      extraFee: extraFee ?? this.extraFee,
      shipperNote: shipperNote ?? this.shipperNote,
    );
  }
}

/// Màn hình Chọn điểm giao hàng KTX (LF-06 - Google Stitch V1)
/// - Bản đồ FlutterMap toàn màn hình hiển thị khuôn viên ĐHQG TP.HCM
/// - Vùng giao hàng hoạt động (Active Delivery Zone)
/// - Ghim vị trí tương tác (Pin Marker) kèm Callout Bubble
/// - Cụm nút điều khiển bản đồ: GPS hiện tại, Reset KTX B, Zoom In/Out
/// - Preset Campus Hotspots: KTX B (BA2), KTX A (A15), Thư viện TT, Bách Khoa CS2
/// - Delivery Bottom Sheet với Drop-off selector (Sảnh G, Cổng bảo vệ, Tận phòng)
/// - Ô nhập ghi chú giao hàng cho shipper với Quick tags (+ Gọi trước 2p, + Để bàn giao đồ)
/// - Nút CTA cố định chuyển tiếp sang CheckoutScreen (LF-07)
class LocationPickerScreen extends StatefulWidget {
  final CampusDeliveryLocation? initialLocation;
  final TileProvider? tileProvider;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.tileProvider,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();

  // Tọa độ mặc định: Sảnh Tòa BA2, KTX Khu B ĐHQG TP.HCM
  static const LatLng _defaultKtxB = LatLng(10.8800, 106.8050);
  static const LatLng _defaultKtxA = LatLng(10.8750, 106.7980);
  static const LatLng _defaultThuVien = LatLng(10.8700, 106.8030);
  static const LatLng _defaultBachKhoa = LatLng(10.8810, 106.8080);

  late LatLng _selectedPosition;
  late String _buildingName;
  late String _subAddress;
  String _dropOffOption = 'g'; // 'g', 'gate', 'door'
  double _dropOffExtraFee = 0.0;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingGps = false;
  String? _gpsErrorMessage;
  int _selectedPresetIndex = 0;

  // Danh sách các địa điểm tiêu biểu trong khuôn viên ĐHQG TP.HCM (Stitch LF-06)
  final List<Map<String, dynamic>> _campusHotspots = [
    {
      'name': '🏢 KTX Khu B (BA2)',
      'building': 'Tòa BA2 - KTX Khu B',
      'address': 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An',
      'pos': _defaultKtxB,
    },
    {
      'name': '🏫 KTX Khu A (A15)',
      'building': 'Tòa A15 - KTX Khu A',
      'address': 'Đường Lạc Long Quân, Linh Trung, Thủ Đức',
      'pos': _defaultKtxA,
    },
    {
      'name': '📚 Thư viện TT',
      'building': 'Thư viện Trung tâm ĐHQG',
      'address': 'Khu phố 6, Linh Trung, TP. Thủ Đức',
      'pos': _defaultThuVien,
    },
    {
      'name': '🏛️ ĐH Bách Khoa CS2',
      'building': 'Giảng đường H6 - Bách Khoa CS2',
      'address': 'Đường Ký Túc Xá Bách Khoa, Dĩ An',
      'pos': _defaultBachKhoa,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedPosition = widget.initialLocation!.position;
      _buildingName = widget.initialLocation!.buildingName;
      _subAddress = widget.initialLocation!.subAddress;
      _dropOffOption = widget.initialLocation!.dropOffOptionKey;
      _dropOffExtraFee = widget.initialLocation!.extraFee;
      _noteController.text = widget.initialLocation!.shipperNote;
      _searchController.text = _buildingName;
    } else {
      _selectedPosition = _defaultKtxB;
      _buildingName = 'Tòa BA2 - KTX Khu B';
      _subAddress = 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An';
      _searchController.text = _buildingName;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSelectPreset(int index) {
    AppHaptics.selection();
    final hotspot = _campusHotspots[index];
    final targetPos = hotspot['pos'] as LatLng;

    setState(() {
      _selectedPresetIndex = index;
      _selectedPosition = targetPos;
      _buildingName = hotspot['building'] as String;
      _subAddress = hotspot['address'] as String;
      _searchController.text = _buildingName;
    });

    _mapController.move(targetPos, 16.5);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    AppHaptics.light();
    setState(() {
      _selectedPosition = point;
      _selectedPresetIndex = -1; // Deselect preset
      _buildingName = 'Điểm ghim tùy chọn';
      _subAddress =
          'Tọa độ: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
      _searchController.text =
          '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
    });
  }

  Future<void> _getCurrentLocation() async {
    AppHaptics.medium();
    setState(() {
      _isLoadingGps = true;
      _gpsErrorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingGps = false;
            _gpsErrorMessage =
                'Vui lòng bật dịch vụ định vị (GPS) trên máy của bạn!';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_gpsErrorMessage!),
              backgroundColor: AppColors.errorApple,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingGps = false;
              _gpsErrorMessage = 'Quyền định vị GPS bị từ chối.';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Quyền định vị GPS bị từ chối. Bạn vẫn có thể chọn điểm trên bản đồ.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingGps = false;
            _gpsErrorMessage =
                'Quyền định vị bị từ chối vĩnh viễn trong Cài đặt hệ thống.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Quyền định vị bị từ chối vĩnh viễn. Vui lòng cấp quyền trong Cài đặt để tự động lấy vị trí.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _selectedPosition = newLatLng;
          _selectedPresetIndex = -1;
          _buildingName = 'Vị trí hiện tại của bạn';
          _subAddress =
              'GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _searchController.text = _buildingName;
          _isLoadingGps = false;
        });
        _mapController.move(newLatLng, 16.5);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
          _gpsErrorMessage = 'Không thể lấy tín hiệu GPS: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi định vị: $e'),
            backgroundColor: AppColors.errorApple,
          ),
        );
      }
    }
  }

  void _onSelectDropOffOption(String key, double fee) {
    AppHaptics.selection();
    setState(() {
      _dropOffOption = key;
      _dropOffExtraFee = fee;
    });
  }

  void _appendQuickNote(String tag) {
    AppHaptics.light();
    final current = _noteController.text.trim();
    if (current.isEmpty) {
      _noteController.text = tag;
    } else if (!current.contains(tag)) {
      _noteController.text = '$current, $tag';
    }
  }

  void _confirmAndProceedToCheckout() {
    AppHaptics.medium();

    String dropOffLabel = 'Sảnh tầng G (Chân thang máy)';
    if (_dropOffOption == 'gate') {
      dropOffLabel = 'Cổng bảo vệ tòa nhà';
    } else if (_dropOffOption == 'door') {
      dropOffLabel = 'Giao tận cửa phòng KTX (+5k)';
    }

    final locationData = CampusDeliveryLocation(
      position: _selectedPosition,
      buildingName: _buildingName,
      subAddress: _subAddress,
      dropOffOptionKey: _dropOffOption,
      dropOffOptionLabel: dropOffLabel,
      extraFee: _dropOffExtraFee,
      shipperNote: _noteController.text.trim(),
    );

    // Chuyển tiếp sang CheckoutScreen (LF-07) theo đúng luồng UI-06
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          deliveryLocation: locationData,
          tileProvider: widget.tileProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: theme.canvas,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1. Bản đồ FlutterMap toàn màn hình
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 16.0,
              minZoom: 13.0,
              maxZoom: 18.5,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.langfood.app',
                tileProvider: widget.tileProvider,
                errorTileCallback: (tile, error, stackTrace) {
                  // Silently ignore tile network issues in offline / test mode
                },
              ),

              // Vùng giao hàng LangFood KTX ĐHQG (Vòng tròn mờ cam)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _defaultKtxB,
                    radius: 750, // Bán kính phủ sóng KTX Khu B
                    useRadiusInMeter: true,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderColor: AppColors.primary.withValues(alpha: 0.5),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              // Điểm ghim vị trí đã chọn (Pin Marker)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 140,
                    height: 90,
                    alignment: Alignment.bottomCenter,
                    child: _buildPinWithCallout(),
                  ),
                ],
              ),
            ],
          ),

          // 2. Thanh tìm kiếm và điều hướng phía trên (Top Overlay)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.marginMobile,
                vertical: AppTokens.spaceSm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Nút Back iOS
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.card.withValues(alpha: 0.95)
                              : Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: AppTokens.shadowLevel2,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: theme.textPrimary,
                          ),
                          onPressed: () {
                            AppHaptics.light();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: AppTokens.spaceSm),

                      // Thanh tìm kiếm địa điểm KTX
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.card.withValues(alpha: 0.95)
                                : Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusFull,
                            ),
                            boxShadow: AppTokens.shadowLevel2,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: AppTypography.bodySm.copyWith(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Tìm tòa KTX, giảng đường...',
                                    hintStyle: AppTypography.bodySm.copyWith(
                                      color: theme.textSecondary.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (query) {
                                    if (query.trim().isNotEmpty) {
                                      setState(() {
                                        _buildingName = query.trim();
                                        _subAddress = 'Địa chỉ nhập tay';
                                      });
                                    }
                                  },
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                InkWell(
                                  onTap: () {
                                    _searchController.clear();
                                  },
                                  child: Icon(
                                    Icons.cancel_rounded,
                                    size: 16,
                                    color: theme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Cụm nút công cụ bản đồ (Map Controls - Zoom, GPS)
          Positioned(
            right: AppTokens.marginMobile,
            top: 110,
            child: Column(
              children: [
                // Nút định vị GPS thực tế
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? theme.card : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppTokens.shadowLevel2,
                  ),
                  child: IconButton(
                    icon: _isLoadingGps
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                    onPressed: _isLoadingGps ? null : _getCurrentLocation,
                  ),
                ),
                const SizedBox(height: 10),

                // Nút thu phóng Zoom In / Out
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? theme.card : Colors.white,
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    boxShadow: AppTokens.shadowLevel2,
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 20),
                        color: theme.textPrimary,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          AppHaptics.light();
                          _mapController.move(
                            _mapController.camera.center,
                            (_mapController.camera.zoom + 1.0).clamp(
                              13.0,
                              18.5,
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 24,
                        height: 0.5,
                        color: theme.borderSubtle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 20),
                        color: theme.textPrimary,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          AppHaptics.light();
                          _mapController.move(
                            _mapController.camera.center,
                            (_mapController.camera.zoom - 1.0).clamp(
                              13.0,
                              18.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Draggable Delivery Bottom Sheet (LF-06 Stitch)
          _buildDeliveryBottomSheet(context),
        ],
      ),
    );
  }

  // Widget hiển thị Pin kèm bong bóng Callout trên bản đồ
  Widget _buildPinWithCallout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Callout Bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  _buildingName,
                  style: const TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),

        // Pin Head
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.electric_moped_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Bottom Sheet chi tiết điểm giao hàng KTX (LF-06)
  Widget _buildDeliveryBottomSheet(BuildContext context) {
    final theme = context.langFoodTheme;
    final isDark = context.isDarkMode;

    return DraggableScrollableSheet(
      initialChildSize: 0.48,
      minChildSize: 0.25,
      maxChildSize: 0.88,
      snap: true,
      snapSizes: const [0.25, 0.48, 0.88],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              AppTokens.marginMobile,
              8,
              AppTokens.marginMobile,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            children: [
              // Thanh kéo (Grabber)
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tiêu đề Sheet & ETA Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết điểm nhận món',
                          style: AppTypography.titleMd.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Khuôn viên Ký túc xá ĐHQG TP.HCM',
                          style: AppTypography.bodySm.copyWith(
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '15 - 20 phút',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Các điểm đến quen thuộc (Preset Campus Hotspots)
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _campusHotspots.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = _campusHotspots[idx];
                    final isSelected = _selectedPresetIndex == idx;
                    return InkWell(
                      onTap: () => _onSelectPreset(idx),
                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? theme.surfaceContainerLow
                                    : const Color(0xFFF3F3F6)),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusFull,
                          ),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: theme.borderSubtle,
                                  width: 0.5,
                                ),
                        ),
                        child: Text(
                          item['name'] as String,
                          style: AppTypography.labelSm.copyWith(
                            color: isSelected
                                ? Colors.white
                                : theme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ hiển thị vị trí nhận hiện tại
              Container(
                padding: const EdgeInsets.all(AppTokens.spaceMd),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.surfaceContainerLow
                      : const Color(0xFFF8F8FA),
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  border: Border.all(color: theme.borderSubtle, width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _buildingName,
                                  style: AppTypography.titleMd.copyWith(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.tertiary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTokens.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  'Đúng tuyến',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.tertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subAddress,
                            style: AppTypography.bodySm.copyWith(
                              color: theme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bộ chọn vị trí shipper gặp bạn (Drop-off Options)
              Text(
                'Vị trí shipper gặp bạn:',
                style: AppTypography.titleMd.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),

              // Option 1: Sảnh Tầng G (Chân Thang Máy)
              _buildDropOffRadioCard(
                context,
                keyName: 'g',
                title: 'Sảnh tầng G (Chân thang máy)',
                subTitle: 'Khu nhận đồ ăn tập trung của tòa nhà',
                badgeText: 'KHUYÊN DÙNG',
                feeText: 'Miễn phí',
                fee: 0.0,
                isFree: true,
              ),
              const SizedBox(height: 8),

              // Option 2: Cổng bảo vệ tòa nhà
              _buildDropOffRadioCard(
                context,
                keyName: 'gate',
                title: 'Cổng bảo vệ tòa nhà',
                subTitle: 'Gửi bảo vệ nếu bạn đang bận học/thi cử',
                feeText: 'Miễn phí',
                fee: 0.0,
                isFree: true,
              ),
              const SizedBox(height: 8),

              // Option 3: Giao tận cửa phòng KTX
              _buildDropOffRadioCard(
                context,
                keyName: 'door',
                title: 'Giao tận cửa phòng KTX',
                subTitle: 'Hỗ trợ shipper gửi xe và bấm thang máy lên phòng',
                feeText: '+5.000₫',
                fee: 5000.0,
                isFree: false,
              ),
              const SizedBox(height: 16),

              // Ghi chú chi tiết cho tài xế KTX
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    'Ghi chú cho shipper:',
                    style: AppTypography.labelMd.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      _buildQuickTagChip(
                        '+ Gọi trước 2p',
                        () => _appendQuickNote('Gọi trước 2p'),
                      ),
                      _buildQuickTagChip(
                        '+ Để bàn giao đồ',
                        () => _appendQuickNote('Để bàn giao đồ'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.surfaceContainerLow
                      : const Color(0xFFF8F8FA),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  border: Border.all(color: theme.borderSubtle, width: 0.5),
                ),
                child: TextField(
                  controller: _noteController,
                  style: AppTypography.bodySm.copyWith(
                    color: theme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Gọi mình xuống lấy đồ, gửi bàn số 2...',
                    hintStyle: AppTypography.bodySm.copyWith(
                      color: theme.textSecondary.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nút CTA cố định: "Xác nhận điểm giao này"
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    ),
                  ),
                  onPressed: _confirmAndProceedToCheckout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Xác nhận điểm giao này',
                          style: AppTypography.titleMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Tài xế LangFood nắm rõ sơ đồ từng tòa KTX ĐHQG',
                        style: AppTypography.labelSm.copyWith(
                          color: theme.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropOffRadioCard(
    BuildContext context, {
    required String keyName,
    required String title,
    required String subTitle,
    required String feeText,
    required double fee,
    required bool isFree,
    String? badgeText,
  }) {
    final theme = context.langFoodTheme;
    final isSelected = _dropOffOption == keyName;

    return InkWell(
      onTap: () => _onSelectDropOffOption(keyName, fee),
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : (context.isDarkMode
                    ? theme.surfaceContainerLow
                    : const Color(0xFFF9F9FB)),
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.borderSubtle,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : theme.textSecondary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.bodyMd.copyWith(
                            color: theme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subTitle,
                    style: AppTypography.bodySm.copyWith(
                      color: theme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              feeText,
              style: AppTypography.labelSm.copyWith(
                color: isFree ? AppColors.tertiary : AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTagChip(String label, VoidCallback onTap) {
    final theme = context.langFoodTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: theme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(color: theme.borderSubtle, width: 0.5),
        ),
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: theme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
