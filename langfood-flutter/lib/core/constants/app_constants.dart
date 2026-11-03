import '../../config/config_url.dart';

class AppConstants {
  static const String appName = 'Làng Food';
  static const String appSlogan = 'Ship đồ ngon - Giá sinh viên';

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
  static const String defaultFoodImage = '';
}
