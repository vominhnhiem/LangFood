import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'Làng Food';
  static const String appSlogan = 'Ship đồ ngon - Giá sinh viên';

  // Backend Port (Fixed at 5289 as recommended)
  static const int apiPort = 5289;

  /// Cấu hình IP kết nối tới Backend:
  /// - Máy ảo Android Emulator (Pixel, Nox, LDPlayer): 10.0.2.2
  /// - Điện thoại thật kết nối cùng Wi-Fi với máy tính: 192.168.2.56
  /// - Web / Windows Desktop: localhost
  static const String emulatorIp = '10.0.2.2';
  static const String lanIp = '192.168.2.56';

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:$apiPort/';
    }
    // Mặc định cho máy ảo Android Emulator
    return 'http://$emulatorIp:$apiPort/';
  }

  // Active Base URL (Có thể chuyển đổi linh hoạt khi đổi thiết bị)
  static String baseUrl = defaultBaseUrl;

  // SharedPreferences Keys
  static const String keyUserId = 'USER_ID';
  static const String keyUsername = 'USERNAME';
  static const String keyFullName = 'FULL_NAME';
  static const String keyRoleId = 'ROLE_ID';
  static const String keyShopId = 'SHOP_ID';
  static const String keyShipperId = 'SHIPPER_ID';
  static const String keyAvatarUrl = 'AVATAR_URL';
  static const String keyJwtToken = 'JWT_TOKEN';

  // Default image
  static const String defaultFoodImage = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500';
  static const String defaultShopAvatar = 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500';
}
