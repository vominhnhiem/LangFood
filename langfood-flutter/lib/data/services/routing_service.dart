import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoadRoute {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  const RoadRoute(this.points, this.distanceMeters, this.durationSeconds);
}

class RoutingService {
  static Future<RoadRoute> getRoute(
    LatLng from,
    LatLng to, {
    http.Client? client,
  }) async {
    final coordinates =
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coordinates',
      {'overview': 'full', 'geometries': 'geojson'},
    );
    final response = await (client == null ? http.get(uri) : client.get(uri))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('Không thể tải chỉ đường.');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List?;
    if (data['code'] != 'Ok' || routes == null || routes.isEmpty) {
      throw Exception('Không tìm được tuyến đường đến điểm giao.');
    }
    final route = routes.first as Map<String, dynamic>;
    final coordinatesJson = route['geometry']['coordinates'] as List;
    return RoadRoute(
      coordinatesJson
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList(),
      (route['distance'] as num).toDouble(),
      (route['duration'] as num).toDouble(),
    );
  }
}
