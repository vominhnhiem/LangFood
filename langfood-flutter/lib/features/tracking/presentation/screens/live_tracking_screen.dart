import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../data/models/order_model.dart';
import '../../../../data/services/order_service.dart';
import '../../../../data/services/routing_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int orderId;
  final bool isShipper;
  const LiveTrackingScreen({
    super.key,
    required this.orderId,
    this.isShipper = false,
  });
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _map = MapController();
  final _service = OrderService();
  Timer? _refreshTimer;
  OrderModel? _order;
  LatLng? _shipper;
  LatLng? _routeOrigin;
  LatLng? _routeDestination;
  RoadRoute? _route;
  DateTime? _routeRequestedAt;
  DateTime? _locationTime;
  bool _loading = true;
  bool _refreshing = false;
  bool _routing = false;
  bool _mapReady = false;
  bool _centered = false;
  String? _error;
  String? _routeError;

  LatLng? get _destination {
    final lat = _order?.deliveryLatitude;
    final lng = _order?.deliveryLongitude;
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    // This timer only fetches server data; it never moves a marker by itself.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final order = await _service.getOrderById(widget.orderId);
      final location = await _service.getShipperLocation(widget.orderId);
      if (!mounted) return;
      if (order == null) throw Exception('Không tải được thông tin đơn hàng.');
      setState(() {
        _order = order;
        _shipper = location == null
            ? null
            : LatLng(
                (location['latitude'] as num).toDouble(),
                (location['longitude'] as num).toDouble(),
              );
        _locationTime = location == null
            ? null
            : DateTime.tryParse(location['updatedAt']?.toString() ?? '');
        _loading = false;
        _error = null;
        if (_shipper == null) _route = null;
      });
      _centerMap();
      if (order.status == 'Completed') {
        _refreshTimer?.cancel();
      } else {
        await _loadRoute();
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
    } finally {
      _refreshing = false;
    }
  }

  void _centerMap() {
    if (!_mapReady || _centered) return;
    final center = _shipper ?? _destination;
    if (center == null) return;
    _map.move(center, 16);
    _centered = true;
  }

  Future<void> _loadRoute({bool force = false}) async {
    final from = _shipper;
    final to = _destination;
    if (from == null || to == null || _routing) return;
    final sameDestination = _routeDestination == to;
    if (!force &&
        sameDestination &&
        _route != null &&
        _routeOrigin != null &&
        const Distance().as(LengthUnit.Meter, _routeOrigin!, from) < 50)
      return;
    if (!force &&
        _routeRequestedAt != null &&
        DateTime.now().difference(_routeRequestedAt!).inSeconds < 10)
      return;
    _routing = true;
    _routeRequestedAt = DateTime.now();
    try {
      final route = await RoutingService.getRoute(from, to);
      if (!mounted) return;
      setState(() {
        _route = route;
        _routeOrigin = from;
        _routeDestination = to;
        _routeError = null;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          _route = null;
          _routeError = e.toString().replaceFirst('Exception: ', '');
        });
    } finally {
      _routing = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${widget.isShipper ? 'Chỉ đường giao' : 'Theo dõi'} #${widget.orderId}',
      ),
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
        : Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter:
                        _destination ??
                        _shipper ??
                        const LatLng(10.8805, 106.8048),
                    initialZoom: 15,
                    onMapReady: () {
                      _mapReady = true;
                      _centerMap();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.langfood_flutter',
                    ),
                    if (_route != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _route!.points,
                            color: Colors.blue,
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_destination != null)
                          Marker(
                            point: _destination!,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 42,
                            ),
                          ),
                        if (_shipper != null)
                          Marker(
                            point: _shipper!,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.delivery_dining,
                              color: Colors.blue,
                              size: 38,
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
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    Text(_order?.deliveryBuilding ?? 'Chưa có địa chỉ'),
                    Text('Trạng thái: ${_order?.status ?? ''}'),
                    if (_shipper == null)
                      const Text('Chưa nhận được vị trí GPS của shipper.'),
                    if (_destination == null)
                      const Text('Đơn này chưa có tọa độ giao hàng.'),
                    if (_locationTime != null)
                      Text('GPS cập nhật: ${_locationTime!.toLocal()}'),
                    if (_route != null)
                      Text(
                        '${(_route!.distanceMeters / 1000).toStringAsFixed(1)} km • khoảng ${(_route!.durationSeconds / 60).ceil()} phút',
                      ),
                    if (_routeError != null)
                      Text(
                        _routeError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    if (_shipper != null && _destination != null)
                      TextButton.icon(
                        onPressed: () => _loadRoute(force: true),
                        icon: const Icon(Icons.directions),
                        label: const Text('Tải lại chỉ đường'),
                      ),
                  ],
                ),
              ),
            ],
          ),
  );
}
