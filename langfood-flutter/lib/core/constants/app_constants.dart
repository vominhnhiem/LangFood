import '../../config/config_url.dart';

class BuildingInfo {
  final String id;
  final String name;
  final String cluster;
  final String address;
  final bool hasElevator;

  const BuildingInfo({
    required this.id,
    required this.name,
    required this.cluster,
    required this.address,
    this.hasElevator = false,
  });
}

class AppConstants {
  static const String appName = 'Làng Food';
  static const String appSlogan = 'Ship đồ ngon - Giá sinh viên';

  static const int apiPort = 5289;

  static String _overrideBaseUrl = '';
  static String get defaultBaseUrl => ConfigUrl.serverUrl;
  static String get baseUrl =>
      _overrideBaseUrl.isNotEmpty ? _overrideBaseUrl : ConfigUrl.serverUrl;
  static set baseUrl(String value) {
    _overrideBaseUrl = value;
  }

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

  // Building information for quick scroll
  static const List<BuildingInfo> ktxKhuBBuildings = [
    // Cụm C (16 tầng - Thang máy)
    BuildingInfo(id: 'C1', name: 'Tòa C1 - KTX Khu B', cluster: 'C', address: 'Đường Lưu Hữu Phước, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'C2', name: 'Tòa C2 - KTX Khu B', cluster: 'C', address: 'Đường Lưu Hữu Phước, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'C3', name: 'Tòa C3 - KTX Khu B', cluster: 'C', address: 'Đường Lưu Hữu Phước, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'C4', name: 'Tòa C4 - KTX Khu B', cluster: 'C', address: 'Đường Lưu Hữu Phước, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'C5', name: 'Tòa C5 - KTX Khu B', cluster: 'C', address: 'Đường Lưu Hữu Phước, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'C6', name: 'Tòa C6 - KTX Khu B', cluster: 'C', address: 'Đường Lưu Hữu Phước, P. Đông Hòa, Dĩ An', hasElevator: true),
    // Cụm D (16 tầng - Thang máy)
    BuildingInfo(id: 'D1', name: 'Tòa D1 - KTX Khu B', cluster: 'D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'D2', name: 'Tòa D2 - KTX Khu B', cluster: 'D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'D3', name: 'Tòa D3 - KTX Khu B', cluster: 'D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'D4', name: 'Tòa D4 - KTX Khu B', cluster: 'D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'D5', name: 'Tòa D5 - KTX Khu B', cluster: 'D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: true),
    BuildingInfo(id: 'D6', name: 'Tòa D6 - KTX Khu B', cluster: 'D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: true),
    // Cụm B.A (5 tầng - Thang bộ)
    BuildingInfo(id: 'BA1', name: 'Tòa B.A1 - KTX Khu B', cluster: 'B.A', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BA2', name: 'Tòa B.A2 - KTX Khu B', cluster: 'B.A', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BA3', name: 'Tòa B.A3 - KTX Khu B', cluster: 'B.A', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BA4', name: 'Tòa B.A4 - KTX Khu B', cluster: 'B.A', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    // Cụm B.B (5 tầng - Thang bộ)
    BuildingInfo(id: 'BB1', name: 'Tòa B.B1 - KTX Khu B', cluster: 'B.B', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BB2', name: 'Tòa B.B2 - KTX Khu B', cluster: 'B.B', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    // Cụm B.C (5 tầng - Thang bộ)
    BuildingInfo(id: 'BC1', name: 'Tòa B.C1 - KTX Khu B', cluster: 'B.C', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BC2', name: 'Tòa B.C2 - KTX Khu B', cluster: 'B.C', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    // Cụm B.D (5 tầng - Thang bộ)
    BuildingInfo(id: 'BD1', name: 'Tòa B.D1 - KTX Khu B', cluster: 'B.D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BD2', name: 'Tòa B.D2 - KTX Khu B', cluster: 'BD2', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BD3', name: 'Tòa B.D3 - KTX Khu B', cluster: 'B.D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BD4', name: 'Tòa B.D4 - KTX Khu B', cluster: 'B.D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    BuildingInfo(id: 'BD5', name: 'Tòa B.D5 - KTX Khu B', cluster: 'B.D', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: false),
    // Tòa Dịch vụ E1
    BuildingInfo(id: 'E1', name: 'Tòa E1 - Dịch Vụ KTX B', cluster: 'E1', address: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An', hasElevator: true),
  ];
}
