import 'package:geolocator/geolocator.dart';

class LocationService {
  static const settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  static Future<void> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS đang tắt. Hãy bật dịch vụ vị trí rồi thử lại.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Cần cấp quyền vị trí để sử dụng GPS.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền vị trí đã bị chặn. Hãy cấp lại trong cài đặt ứng dụng.',
      );
    }
  }

  static Future<Position> current() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 20),
    );
  }
}
