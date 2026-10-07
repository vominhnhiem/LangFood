class AppConstants {
  static const String appName = 'Làng Food';
  static const String appSlogan = 'Ship đồ ngon - Giá sinh viên';

  // Backend Port (Fixed at 5289 as recommended)
  static const int apiPort = 5289;

  /// Default Base URL
  /// - Real LAN IP: http://192.168.100.192:5289/
  /// - Android Emulator: http://10.0.2.2:5289/
  /// - iOS Simulator / Desktop / Web: http://localhost:5289/
  static String get defaultBaseUrl {
    return 'http://10.19.18.38:$apiPort/';
  }

  // Active Base URL (Can be changed dynamically if running on real device)
  static String baseUrl = 'http://10.19.18.38:$apiPort/';

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
