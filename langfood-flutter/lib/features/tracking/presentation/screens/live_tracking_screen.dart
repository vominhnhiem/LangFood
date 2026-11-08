import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../config/config_url.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_campus_route.dart';
import '../../../../core/utils/display_format.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';

import '../../../../data/services/routing_service.dart';

// Màn hình Chọn Vai Trò (Shipper hoặc Khách Hàng) để test bản đồ
class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.langFoodTheme.canvas,
      appBar: AppBar(
        title: const Text("LangFood - Chọn Vai Trò Test"),
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.directions_bike,
                    color: Colors.white,
                    size: 28,
                  ),
                  label: const Text(
                    "Tôi là Shipper (Giao Hàng)",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveTrackingScreen(
                          isShipper: true,
                          orderId: 105,
                        ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.white,
                    size: 28,
                  ),
                  label: const Text(
                    "Tôi là Khách Hàng (Đặt Đồ)",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveTrackingScreen(
                          isShipper: false,
                          orderId: 105,
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
}

class LiveTrackingScreen extends StatefulWidget {
  final int orderId;
  final bool isShipper;
  final LatLng? initialCustomerPos;
  final String? initialAddress;
  final bool isLocationLocked;
  final OrderService? service;
  final TileProvider? tileProvider;
  final bool enablePeriodicTimer;
  final bool autoShareGps;
  const LiveTrackingScreen({
    super.key,
    required this.orderId,
    this.isShipper = false,
    this.initialCustomerPos,
    this.initialAddress,
    this.isLocationLocked = false,
    this.service,
    this.tileProvider,
    this.enablePeriodicTimer = true,
    this.autoShareGps = false,
  });
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _map = MapController();
  late final OrderService _service = widget.service ?? OrderService();
  Timer? _timer;
  StreamSubscription<Position>? _gps;
  OrderModel? _order;
  LatLng? _shipper;
  RoadRoute? _route;
  String? _error;
  String? _routeError;
  DateTime? _locationTime;
  LatLng? _routeOrigin;
  bool _loading = true;
  bool _fetching = false;
  bool _sharing = false;
  bool _sendingLocation = false;
  bool _completing = false;
  bool _mapReady = false;
  LatLng? _pickupPosition;
  String? _pickupAddress;
  bool _confirmingPickup = false;
  bool _autoShareAttempted = false;
  bool _startingGps = false;
  String? _gpsError;

  static const double maxGeofenceDistanceMeters = 200.0;

  LatLng? get _destination {
    if (_order?.status == 'PickingUp') {
      return _pickupPosition;
    }
    final lat = _order?.deliveryLatitude;
    final lng = _order?.deliveryLongitude;
    if (lat != null && lng != null) return LatLng(lat, lng);
    return widget.initialCustomerPos;
  }

  double? get _distanceToTargetMeters {
    final shipperPos = _shipper;
    final destPos = _destination;
    if (shipperPos == null || destPos == null) return null;
    return const Distance().as(LengthUnit.Meter, shipperPos, destPos);
  }

  bool get _isWithinGeofence {
    final dist = _distanceToTargetMeters;
    if (dist == null) return true;
    return dist <= maxGeofenceDistanceMeters;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    if (widget.enablePeriodicTimer) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gps?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final order = await _service.getOrderById(widget.orderId);
      if (order == null)
        throw Exception('Không tìm thấy đơn hàng #${widget.orderId}.');
      final pickingUp = order.status == 'PickingUp';
      final tracking = pickingUp || order.status == 'Delivering';
      if (pickingUp && _pickupAddress == null) {
        try {
          final pickup = await _service.getShopPickup(order.shopId);
          final lat = pickup['latitude'];
          final lng = pickup['longitude'];
          if (lat is num && lng is num && lat.abs() <= 90 && lng.abs() <= 180) {
            _pickupPosition = LatLng(lat.toDouble(), lng.toDouble());
          }
          _pickupAddress = pickup['address'] as String?;
        } catch (_) {
          // Retry loading the pickup details on the next refresh.
        }
      }
      final location = tracking
          ? await _service.getShipperLocation(widget.orderId)
          : null;
      if (!mounted) return;
      LatLng? position;
      if (location?['latitude'] is num && location?['longitude'] is num) {
        final lat = (location!['latitude'] as num).toDouble();
        final lng = (location['longitude'] as num).toDouble();
        if (lat.isFinite &&
            lng.isFinite &&
            lat.abs() <= 90 &&
            lng.abs() <= 180) {
          position = LatLng(lat, lng);
        }
      }
      setState(() {
        if (_order?.status != order.status || position == null) {
          _route = null;
          _routeOrigin = null;
          _routeError = null;
        }
        _order = order;
        _shipper = position;
        _loading = false;
        _error = null;
        _locationTime = DateTime.tryParse(
          location?['updatedAt']?.toString() ?? '',
        );
      });
      if (order.isFinished) {
        _timer?.cancel();
      }
      if (!tracking && _sharing) {
        await _gps?.cancel();
        if (mounted) setState(() => _sharing = false);
      }
      if (widget.autoShareGps &&
          widget.isShipper &&
          tracking &&
          !_autoShareAttempted &&
          !_sharing) {
        _autoShareAttempted = true;
        unawaited(_shareGps());
      }
      if (position != null && _destination != null && tracking) {
        if (_routeOrigin == null ||
            const Distance().as(LengthUnit.Meter, _routeOrigin!, position) >=
                30) {
          try {
            final route = await RoutingService.getRoute(
              position,
              _destination!,
            );
            if (mounted)
              setState(() {
                _route = route;
                _routeOrigin = position;
                _routeError = null;
              });
          } catch (_) {
            if (mounted)
              setState(() {
                _route = null;
                _routeError =
                    'Chưa tải được tuyến đường. Vị trí vẫn được cập nhật.';
              });
          }
        }
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
    } finally {
      _fetching = false;
    }
  }

  void _centerMap() {
    if (!_mapReady) return;
    if (_shipper != null && _destination != null) {
      _map.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_shipper!, _destination!]),
          padding: const EdgeInsets.fromLTRB(40, 80, 40, 300),
        ),
      );
    } else if (_destination != null) {
      _map.move(_destination!, 15);
    }
  }

  Future<void> _shareGps() async {
    if (_startingGps) return;
    if (_sharing) {
      await _gps?.cancel();
      if (mounted) setState(() => _sharing = false);
      return;
    }
    final shipperId = context.read<AuthProvider>().user?.shipperId;
    if (shipperId == null ||
        _order?.shipperId != shipperId ||
        (_order?.status != 'Delivering' && _order?.status != 'PickingUp'))
      return;
    _startingGps = true;
    setState(() => _gpsError = null);
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception('Vui lòng bật GPS.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Chưa được cấp quyền vị trí.');
      }
      if (!mounted ||
          _order?.shipperId != shipperId ||
          (_order?.status != 'Delivering' && _order?.status != 'PickingUp')) {
        return;
      }
      setState(() => _sharing = true);
      _gps =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (position) async {
              if (_sendingLocation || !mounted || !_sharing) return;
              _sendingLocation = true;
              assert(() {
                debugPrint(
                  'GPS_SAMPLE order=${widget.orderId} '
                  'accuracyMeters=${position.accuracy.toStringAsFixed(1)} '
                  'mocked=${position.isMocked} timestamp=${position.timestamp}',
                );
                return true;
              }());
              try {
                final uploadTimer = Stopwatch()..start();
                final saved = await _service.updateShipperLocation(
                  orderId: widget.orderId,
                  latitude: position.latitude,
                  longitude: position.longitude,
                  shipperId: shipperId,
                  headingDegree: position.heading,
                  speedKmh: position.speed * 3.6,
                );
                assert(() {
                  debugPrint(
                    'GPS_UPLOAD order=${widget.orderId} '
                    'success=$saved elapsedMs=${uploadTimer.elapsedMilliseconds}',
                  );
                  return true;
                }());
                if (!saved) throw Exception('Không gửi được vị trí.');
                if (mounted && _gpsError != null) {
                  setState(() => _gpsError = null);
                }
                await _refresh();
              } catch (error) {
                if (mounted) setState(() => _gpsError = error.toString());
              } finally {
                _sendingLocation = false;
              }
            },
            onError: (Object error) {
              if (mounted)
                setState(() {
                  _sharing = false;
                  _gpsError = 'Không đọc được GPS: $error';
                });
            },
            cancelOnError: true,
          );
    } catch (error) {
      if (mounted)
        setState(() {
          _sharing = false;
          _gpsError = error.toString().replaceFirst('Exception: ', '');
        });
    } finally {
      _startingGps = false;
    }
  }

  Future<LatLng?> _resolveShipperPosition() async {
    if (_shipper != null) return _shipper;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      final resolved = LatLng(pos.latitude, pos.longitude);
      if (mounted) setState(() => _shipper = resolved);
      return resolved;
    } catch (_) {
      return null;
    }
  }

  Widget _buildGeofenceStatusCard() {
    final isPickingUp = _order?.status == 'PickingUp';
    final targetName = isPickingUp ? 'quán lấy món' : 'điểm giao hàng';
    final dist = _distanceToTargetMeters;

    if (_destination == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chưa có tọa độ GPS của $targetName. Có thể xác nhận trực tiếp.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      );
    }

    if (_shipper == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.gps_fixed, size: 20, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa bật chia sẻ GPS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  Text(
                    'Bật chia sẻ GPS bên dưới để hệ thống kiểm tra bạn đã đến gần $targetName (< 200m).',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isNear = dist! <= maxGeofenceDistanceMeters;
    final color = isNear ? AppColors.success : Colors.orange.shade800;
    final bgColor = isNear
        ? AppColors.success.withValues(alpha: 0.1)
        : Colors.orange.shade50;
    final icon = isNear ? Icons.check_circle_rounded : Icons.fmd_bad_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNear
                      ? 'Đã vào phạm vi (Cách $targetName: ${dist.round()}m)'
                      : 'Chưa vào phạm vi (Cách $targetName: ${dist.round()}m)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  isNear
                      ? 'Cự ly hợp lệ (< 200m). Bạn có thể bấm xác nhận.'
                      : 'Cần di chuyển lại gần dưới ${maxGeofenceDistanceMeters.toInt()}m để bấm xác nhận.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPickup() async {
    final shipperId = context.read<AuthProvider>().user?.shipperId;
    if (shipperId == null || _confirmingPickup) return;

    final currentShipper = await _resolveShipperPosition();
    if (_destination != null && currentShipper == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vui lòng bật chia sẻ GPS để hệ thống kiểm tra bạn đã đến quán.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (currentShipper != null && _destination != null) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        currentShipper,
        _destination!,
      );
      if (distance > maxGeofenceDistanceMeters) {
        if (mounted) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_off_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Chưa đến gần quán'),
                ],
              ),
              content: Text(
                'Bạn đang cách điểm lấy món ${distance.round()}m.\n\n'
                'Vui lòng di chuyển lại gần quán (dưới ${maxGeofenceDistanceMeters.toInt()}m) để bấm xác nhận đã lấy món.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    setState(() => _confirmingPickup = true);
    try {
      final success = await _service.confirmPickup(
        widget.orderId,
        shipperId,
        lat: currentShipper?.latitude,
        lng: currentShipper?.longitude,
      );
      if (!success) {
        throw Exception('Không thể xác nhận lấy món. Vui lòng thử lại.');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã xác nhận lấy món thành công! Bắt đầu giao đến KTX.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirmingPickup = false);
    }
  }

  Future<void> _complete() async {
    if (_completing) return;

    final currentShipper = await _resolveShipperPosition();
    if (_destination != null && currentShipper == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vui lòng bật chia sẻ GPS để hệ thống kiểm tra bạn đã đến điểm giao.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    double? distance;
    if (currentShipper != null && _destination != null) {
      distance = const Distance().as(
        LengthUnit.Meter,
        currentShipper,
        _destination!,
      );
      if (distance > maxGeofenceDistanceMeters) {
        if (mounted) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_off_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Chưa đến điểm giao'),
                ],
              ),
              content: Text(
                'Bạn đang cách điểm giao hàng ${distance!.round()}m.\n\n'
                'Vui lòng di chuyển lại gần điểm giao (dưới ${maxGeofenceDistanceMeters.toInt()}m) để bấm xác nhận giao hàng.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    final distanceNotice = distance != null
        ? ' (Khoảng cách: ${distance.round()}m)'
        : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã giao món?'),
        content: Text(
          'Chỉ xác nhận khi khách đã nhận đầy đủ món$distanceNotice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đã giao xong'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _completing = true);
    try {
      final success = await _service.completeOrder(
        widget.orderId,
        lat: currentShipper?.latitude,
        lng: currentShipper?.longitude,
      );
      if (!success) {
        throw Exception('Không thể hoàn tất đơn. Vui lòng thử lại.');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Giao hàng thành công! Đơn hàng #${widget.orderId} đã hoàn tất.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.langFoodTheme;
    final destination = _destination;
    final ownsDelivery =
        widget.isShipper &&
        (_order?.status == 'Delivering' || _order?.status == 'PickingUp') &&
        _order?.shipperId != null &&
        _order?.shipperId == context.read<AuthProvider>().user?.shipperId;
    return Scaffold(
      backgroundColor: theme.canvas,
      appBar: AppBar(
        title: Text(
          'Theo dõi #${widget.orderId}',
          style: AppTypography.titleMd.copyWith(
            fontFeatures: AppTypography.currencyDisplay.fontFeatures,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? 'Không tải được đơn hàng.'),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter:
                        destination ?? const LatLng(10.8800, 106.8050),
                    initialZoom: 15,
                    onMapReady: () {
                      _mapReady = true;
                      _centerMap();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: ConfigUrl.mapTileUrl,
                      fallbackUrl: ConfigUrl.mapTileFallbackUrl,
                      userAgentPackageName: 'com.langfood.app',
                      tileProvider: widget.tileProvider,
                    ),
                    if (_route != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _route!.points,
                            strokeWidth: 5,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (destination != null)
                          Marker(
                            point: destination,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_on,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                        if (_shipper != null)
                          Marker(
                            point: _shipper!,
                            width: 48,
                            height: 48,
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.delivery_dining,
                                color: AppColors.tertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: FloatingActionButton(
                    heroTag: null,
                    tooltip: 'Căn chỉnh bản đồ',
                    onPressed: _centerMap,
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: ownsDelivery ? .52 : .32,
                  minChildSize: .25,
                  maxChildSize: .85,
                  snap: !MediaQuery.disableAnimationsOf(context),
                  snapSizes: const [.32, .52],
                  snapAnimationDuration: AppMotion.durationNormal,
                  builder: (context, controller) => Container(
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: theme.borderSubtle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: AppMotion.durationOf(
                                  context,
                                  AppMotion.durationNormal,
                                ),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: AlignmentDirectional.centerStart,
                                  children: [
                                    ...previous,
                                    if (current != null) current,
                                  ],
                                ),
                                child: Text(
                                  _order!.statusLabel,
                                  key: ValueKey(_order!.status),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                ),
                              ),
                            ),
                            if (!widget.isShipper)
                              LangFoodCampusRoute(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (ownsDelivery && _order!.status == 'PickingUp') ...[
                          const Text('ĐIỂM LẤY MÓN'),
                          Text(
                            _pickupAddress ?? 'Chưa tải được địa chỉ quán',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_pickupPosition == null)
                            const Text('Chưa có tọa độ quán để chỉ đường.'),
                        ] else ...[
                          const Text('ĐIỂM GIAO'),
                          Text(
                            _order!.deliveryBuilding ??
                                widget.initialAddress ??
                                'Chưa có địa chỉ giao',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_order!.deliveryRoom?.isNotEmpty == true)
                            Text(_order!.deliveryRoom!),
                        ],
                        if (ownsDelivery) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            icon: Icon(
                              _isWithinGeofence
                                  ? Icons.check_circle_outline
                                  : Icons.lock_outline,
                              size: 18,
                            ),
                            onPressed: _order!.status == 'PickingUp'
                                ? (_confirmingPickup ? null : _confirmPickup)
                                : (_completing ? null : _complete),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(48, 56),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            label: Text(
                              _order!.status == 'PickingUp'
                                  ? (_isWithinGeofence
                                        ? 'Đã lấy món tại quán'
                                        : 'Lại gần quán để xác nhận')
                                  : (_isWithinGeofence
                                        ? 'Đã giao xong'
                                        : 'Lại gần điểm giao để xác nhận'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGeofenceStatusCard(),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _shareGps,
                            icon: const Icon(Icons.my_location),
                            label: Text(
                              _sharing
                                  ? 'Dừng chia sẻ GPS'
                                  : 'Chia sẻ GPS khi giao hàng',
                            ),
                          ),
                        ],
                        if (_order!.status == 'Delivering' && _shipper == null)
                          const Text('Đang chờ vị trí từ tài xế.'),
                        if (_locationTime != null)
                          Text(
                            'Vị trí cập nhật: ${dateText(_locationTime!.toIso8601String())}',
                          ),
                        if (_route != null)
                          Text(
                            'Lộ trình tham khảo: ${(_route!.distanceMeters / 1000).toStringAsFixed(1)} km • ${(_route!.durationSeconds / 60).ceil()} phút',
                          ),
                        if (_routeError != null) Text(_routeError!),
                        if (_gpsError != null) Text(_gpsError!),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        const Divider(height: 24),
                        ..._order!.orderItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.quantity}x ${item.productName ?? 'Món #${item.productId}'}',
                                ),
                                if (item.optionsSummary?.isNotEmpty == true)
                                  Text(item.optionsSummary!),
                                if (item.note?.isNotEmpty == true)
                                  Text(item.note!),
                              ],
                            ),
                          ),
                        ),
                        Text('Tiền món: ${money(_order!.totalAmount)}'),
                        Text('Phí giao: ${money(_order!.shippingFee)}'),
                        Text(
                          'Tổng: ${money(_order!.totalAmount + (_order!.shippingFee ?? 0))}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: MediaQuery.paddingOf(context).bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
