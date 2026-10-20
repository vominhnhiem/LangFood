/// Model dữ liệu cửa hàng / quán ăn (Shop)
/// Tương thích 100% với entity Shop.cs của backend ASP.NET Core
class ShopModel {
  final int id;
  final String userId;
  final String name;
  final String address;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final bool isOpen;
  final double? rating;
  final int? reviewCount;
  final String? prepTime;
  final String? distance;
  final bool isVerified;
  final String? voucherCode;
  final String? voucherDiscount;
  final String? voucherDescription;

  ShopModel({
    required this.id,
    this.userId = '',
    required this.name,
    required this.address,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.isOpen = true,
    this.rating,
    this.reviewCount,
    this.prepTime,
    this.distance,
    this.isVerified = false,
    this.voucherCode,
    this.voucherDiscount,
    this.voucherDescription,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['Id'] ?? 0;
    final name = (json['name'] ?? json['Name'] ?? 'Quán ăn Làng Food')
        .toString();
    // Phân biệt rõ ràng giữa dữ liệu mẫu LF-02 Stitch Demo và quán thực tế
    final isDemoFixture = id == 1 || name == 'Cơm Gà Xối Mỡ Bà Tám';

    final rawRating = json['rating'] ?? json['Rating'];
    final rawReviewCount = json['reviewCount'] ?? json['ReviewCount'];
    final rawPrepTime = json['prepTime'] ?? json['PrepTime'];
    final rawDistance = json['distance'] ?? json['Distance'];
    final rawVoucher = json['voucherCode'] ?? json['VoucherCode'];

    return ShopModel(
      id: id,
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      name: name,
      address:
          (json['address'] ?? json['Address'] ?? 'Ký túc xá Khu B, ĐHQG-HCM')
              .toString(),
      description: json['description'] ?? json['Description'],
      imageUrl: json['imageUrl'] ?? json['ImageUrl'],
      isActive: json['isActive'] ?? json['IsActive'] ?? true,
      isOpen: json['isOpen'] ?? json['IsOpen'] ?? true,
      rating: rawRating != null
          ? (rawRating as num).toDouble()
          : (isDemoFixture ? 4.9 : null),
      reviewCount: rawReviewCount != null
          ? (rawReviewCount as num).toInt()
          : (isDemoFixture ? 1200 : null),
      prepTime:
          rawPrepTime?.toString() ?? (isDemoFixture ? '15-20 phút' : null),
      distance:
          rawDistance?.toString() ?? (isDemoFixture ? '350m từ KTX B' : null),
      isVerified: json['isVerified'] ?? json['IsVerified'] ?? isDemoFixture,
      voucherCode:
          rawVoucher?.toString() ?? (isDemoFixture ? 'SINHVIENKHOE' : null),
      voucherDiscount:
          (json['voucherDiscount'] ?? json['VoucherDiscount'])?.toString() ??
          (isDemoFixture ? 'Giảm 15.000₫' : null),
      voucherDescription:
          (json['voucherDescription'] ?? json['VoucherDescription'])
              ?.toString() ??
          (isDemoFixture
              ? 'Tặng kèm canh rong biển & trà tắc từ 2 phần'
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'isOpen': isOpen,
    };
  }
}
