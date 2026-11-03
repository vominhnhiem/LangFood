import '../../config/config_url.dart';

class AppConstants {
  static const String appName = 'Làng Food';
  static const String appSlogan = 'Ship đồ ngon - Giá sinh viên';

  static const int apiPort = 5289;

  static String get defaultBaseUrl => ConfigUrl.serverUrl;

  static String get baseUrl => ConfigUrl.serverUrl;

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
  static const String defaultFoodImage =
      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500';
  static const String defaultShopAvatar =
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=500';
}
