class UserModel {
  final String id;
  final String username;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final int roleId;
  final int? buildingId;
  final String? ktxRoom;
  final String? avatarUrl;
  final bool isApproved;
  final int? shopId;
  final String? shopName;
  final int? shipperId;

  UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.roleId = 1,
    this.buildingId,
    this.ktxRoom,
    this.avatarUrl,
    this.isApproved = false,
    this.shopId,
    this.shopName,
    this.shipperId,
  });

  String get roleName {
    switch (roleId) {
      case 1:
        return 'Khách hàng (Sinh viên)';
      case 2:
        return 'Chủ quán (Seller)';
      case 3:
        return 'Tài xế (Shipper)';
      case 4:
        return 'Quản trị viên (Admin)';
      default:
        return 'Người dùng';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    int? sId = json['shopId'] ?? json['ShopId'];
    String? sName = json['shopName'] ?? json['ShopName'];
    if (json['shop'] != null && json['shop'] is Map<String, dynamic>) {
      sId ??= json['shop']['id'] ?? json['shop']['Id'];
      sName ??= json['shop']['name'] ?? json['shop']['Name'];
    }

    int? shId = json['shipperId'] ?? json['ShipperId'];
    if (json['shipper'] != null && json['shipper'] is Map<String, dynamic>) {
      shId ??= json['shipper']['id'] ?? json['shipper']['Id'];
    }

    return UserModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      username: (json['username'] ?? json['Username'] ?? '').toString(),
      fullName: json['fullName'] ?? json['FullName'],
      email: json['email'] ?? json['Email'],
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'],
      roleId: json['roleId'] ?? json['RoleId'] ?? 1,
      buildingId: json['buildingId'] ?? json['BuildingId'],
      ktxRoom: json['ktxRoom'] ?? json['KtxRoom'],
      avatarUrl: json['avatarUrl'] ?? json['AvatarUrl'],
      isApproved: json['isApproved'] ?? json['IsApproved'] ?? false,
      shopId: sId,
      shopName: sName ?? json['shopName'] ?? json['ShopName'],
      shipperId: shId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'roleId': roleId,
      'buildingId': buildingId,
      'ktxRoom': ktxRoom,
      'avatarUrl': avatarUrl,
      'isApproved': isApproved,
    };
  }
}
