import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../../core/constants/app_constants.dart';

// Màn hình Chọn Vai Trò (Shipper hoặc Khách Hàng)
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

// Thuật toán Haversine đo khoảng cách mặt cầu giữa 2 tọa độ (Slide 4)
double calculateHaversineDistance(LatLng p1, LatLng p2) {
  const double R = 6371.0; // Bán kính Trái Đất (km)
  double dLat = _degreesToRadians(p2.latitude - p1.latitude);
  double dLng = _degreesToRadians(p2.longitude - p1.longitude);

  double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degreesToRadians(p1.latitude)) *
          math.cos(_degreesToRadians(p2.latitude)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);

  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c; // Khoảng cách Haversine tính bằng km
}

double _degreesToRadians(double degrees) {
  return degrees * math.pi / 180.0;
}

class RouteDetails {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  RouteDetails({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

// Hàm lấy đường đi ngắn nhất + khoảng cách & thời gian từ OSRM API
Future<RouteDetails?> getShortestRouteDetails(LatLng start, LatLng end) async {
  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/'
    '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
    '?overview=full&geometries=geojson'
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final route = data['routes'][0];
      final List coordinates = route['geometry']['coordinates'];
      final double distanceMeters = (route['distance'] as num).toDouble();
      final double durationSeconds = (route['duration'] as num).toDouble();

      final points = coordinates.map((coord) {
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }).toList();

      return RouteDetails(
        points: points,
        distanceKm: distanceMeters / 1000.0,
        durationMinutes: durationSeconds / 60.0,
      );
    }
  } catch (e) {
    debugPrint("Lỗi lấy đường đi: $e");
  }
  return null;
}

class LiveTrackingScreen extends StatefulWidget {
  final bool isShipper; // True: Máy Shipper, False: Máy Khách hàng
  final LatLng? initialCustomerPos;
  final String? initialAddress;
  final bool isLocationLocked;

  const LiveTrackingScreen({
    super.key,
    required this.isShipper,
    this.initialCustomerPos,
    this.initialAddress,
    this.isLocationLocked = false,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _shipperPeriodicTimer;

  LatLng shipperPos = const LatLng(10.8751, 106.7997);   // Vị trí Shipper
  LatLng customerPos = const LatLng(10.8800, 106.8050);  // Vị trí Khách hàng đặt đồ ăn
  String customerAddress = 'Sảnh KTX Khu B, Thủ Đức';

  List<LatLng> routePoints = [];
  double distanceKm = 0;
  double durationMinutes = 0;

  late HubConnection _hubConnection;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomerPos != null) {
      customerPos = widget.initialCustomerPos!;
    }
    if (widget.initialAddress != null) {
      customerAddress = widget.initialAddress!;
    }
    _fetchRoute();
    _initSignalR();

    if (widget.isShipper) {
      _initRealGPS();
      _startShipper5sTimer();
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _shipperPeriodicTimer?.cancel();
    super.dispose();
  }

  // Khởi chạy Timer 5s tự động cập nhật vị trí GPS thực tế của Shipper
  void _startShipper5sTimer() {
    _shipperPeriodicTimer?.cancel();
    _shipperPeriodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || !widget.isShipper) return;

      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        _onNewPosition(position);
      } catch (e) {
        // Nếu GPS chưa kịp phản hồi, gửi vị trí hiện tại qua SignalR
        if (_isConnected) {
          _hubConnection.invoke("UpdateLocation", args: ["Shipper_Phone", shipperPos.latitude, shipperPos.longitude]);
        }
      }
    });
  }

  // Xin quyền & lấy vị trí GPS thực tế của điện thoại
  Future<void> _initRealGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("GPS chưa được bật trên thiết bị!");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _onNewPosition(position);

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      _onNewPosition(position);
    });
  }

  void _onNewPosition(Position position) {
    if (!mounted) return;
    updateShipperLocation(position.latitude, position.longitude);
    _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
  }

  // Khởi tạo kết nối SignalR với Backend C# (.NET)
  Future<void> _initSignalR() async {
    // Tự động lấy URL từ AppConstants.baseUrl
    final baseUrl = AppConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
    final serverUrl = "$baseUrl/locationHub";

    _hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: HttpConnectionOptions())
        .build();

    // Lắng nghe sự kiện từ Backend
    _hubConnection.on("ReceiveLocation", (arguments) {
      if (arguments != null && arguments.length >= 3) {
        final senderId = arguments[0] as String;
        final lat = (arguments[1] as num).toDouble();
        final lng = (arguments[2] as num).toDouble();

        if (senderId == "Customer_Phone" && widget.isShipper) {
          // Shipper nhận vị trí điểm giao đồ ăn do Khách đặt
          setState(() {
            customerPos = LatLng(lat, lng);
          });
          _fetchRoute();
        } else if (senderId == "Shipper_Phone" && !widget.isShipper) {
          // Khách nhận vị trí Shipper đang di chuyển
          setState(() {
            shipperPos = LatLng(lat, lng);
          });
          _fetchRoute();
        }
      }
    });

    try {
      await _hubConnection.start();
      setState(() {
        _isConnected = true;
      });
      debugPrint("Đã kết nối SignalR thành công!");
    } catch (e) {
      debugPrint("Lỗi kết nối SignalR: $e");
    }
  }

  // Gọi API OSRM lấy đường đi + khoảng cách & thời gian
  Future<void> _fetchRoute() async {
    RouteDetails? details = await getShortestRouteDetails(shipperPos, customerPos);
    if (mounted && details != null) {
      setState(() {
        routePoints = details.points;
        distanceKm = details.distanceKm;
        durationMinutes = details.durationMinutes;
      });
    }
  }

  // Cập nhật vị trí Shipper
  void updateShipperLocation(double newLat, double newLng) {
    setState(() {
      shipperPos = LatLng(newLat, newLng);
    });
    _fetchRoute();

    if (widget.isShipper && _isConnected) {
      _hubConnection.invoke("UpdateLocation", args: ["Shipper_Phone", newLat, newLng]);
    }
  }

  // Cập nhật điểm giao đồ ăn do Khách chọn
  void updateCustomerLocation(LatLng newPos) {
    setState(() {
      customerPos = newPos;
    });
    _fetchRoute();

    // Bắn vị trí điểm giao hàng mới sang cho Shipper qua SignalR
    if (!widget.isShipper && _isConnected) {
      _hubConnection.invoke("UpdateLocation", args: ["Customer_Phone", newPos.latitude, newPos.longitude]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isShipper 
            ? 'Shipper (${_isConnected ? "Online" : "Connecting..."})' 
            : 'Khách Đặt Đồ (${_isConnected ? "Online" : "Connecting..."})',
        ),
        backgroundColor: widget.isShipper ? Colors.orange : Colors.green,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: customerPos,
              initialZoom: 16.0,
              // Cho phép chạm bản đồ để chọn điểm giao hàng (chỉ khi chưa bị khóa)
              onTap: (tapPosition, point) {
                if (!widget.isShipper) {
                  if (widget.isLocationLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔒 Điểm giao hàng đã được chốt cố định, không thể dời đi nơi khác!'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    updateCustomerLocation(point);
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.langfood.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5.0,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Marker Shipper
                  Marker(
                    point: shipperPos,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.directions_bike, color: Colors.red, size: 40),
                  ),
                  // Marker Khách hàng (Điểm giao đồ ăn)
                  Marker(
                    point: customerPos,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: Colors.green, size: 45),
                  ),
                ],
              ),
            ],
          ),

          // Banner trạng thái kết nối & cập nhật vị trí
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: widget.isShipper ? Colors.orange.shade800 : Colors.green.shade800,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_tethering,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isShipper
                            ? '🛰️ GPS Shipper tự động gửi vị trí thực tế mỗi 5 giây'
                            : '🟢 Nhận vị trí Shipper realtime từ Server (5s/lần)',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Card thông tin giao hàng bên dưới màn hình
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
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fastfood, color: Colors.orange, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isShipper ? "Đang giao đến khách" : "Điểm giao đồ ăn của bạn",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.isShipper 
                                  ? "Lat: ${customerPos.latitude.toStringAsFixed(4)}, Lng: ${customerPos.longitude.toStringAsFixed(4)}"
                                  : (widget.isLocationLocked
                                      ? "🔒 Địa chỉ đã chốt: $customerAddress"
                                      : "Chạm vào bản đồ để chọn/đổi điểm giao"),
                                style: TextStyle(
                                  color: widget.isLocationLocked ? Colors.black87 : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: widget.isLocationLocked ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.straighten, color: Colors.blue, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "${distanceKm.toStringAsFixed(2)} km",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.red, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "${durationMinutes.ceil()} phút",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 110),
        child: FloatingActionButton(
          backgroundColor: Colors.orange,
          child: Icon(widget.isShipper ? Icons.my_location : Icons.gps_fixed),
          onPressed: () {
            if (widget.isShipper) {
              _initRealGPS();
            } else {
              _mapController.move(customerPos, 16.0);
            }
          },
        ),
      ),
    );
  }
}
