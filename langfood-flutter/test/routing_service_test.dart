import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:langfood_flutter/data/services/routing_service.dart';

void main() {
  test(
    'OSRM uses longitude first and converts GeoJSON to map coordinates',
    () async {
      final client = MockClient((request) async {
        expect(request.url.scheme, 'https');
        expect(request.url.path, '/route/v1/driving/106.8,10.88;106.81,10.89');
        expect(request.url.queryParameters['geometries'], 'geojson');
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 1200.0,
                'duration': 240.0,
                'geometry': {
                  'coordinates': [
                    [106.8, 10.88],
                    [106.81, 10.89],
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final route = await RoutingService.getRoute(
        const LatLng(10.88, 106.8),
        const LatLng(10.89, 106.81),
        client: client,
      );
      expect(route.points.first.latitude, 10.88);
      expect(route.points.last.longitude, 106.81);
      expect(route.distanceMeters, 1200);
      expect(route.durationSeconds, 240);
    },
  );

  test('no route is reported instead of inventing a straight line', () async {
    final client = MockClient(
      (_) async => http.Response('{"code":"NoRoute","routes":[]}', 200),
    );
    await expectLater(
      RoutingService.getRoute(
        const LatLng(10, 106),
        const LatLng(11, 107),
        client: client,
      ),
      throwsException,
    );
  });

  test('routing HTTP failures are surfaced', () async {
    final client = MockClient(
      (_) async => http.Response('Service unavailable', 503),
    );
    await expectLater(
      RoutingService.getRoute(
        const LatLng(10, 106),
        const LatLng(11, 107),
        client: client,
      ),
      throwsException,
    );
  });
}
