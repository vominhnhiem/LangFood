import 'product_option_model.dart';

class ProductModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final int shopId;
  final String shopName;
  final int? categoryId;
  final String? categoryName;
  final List<ProductOptionGroupModel> optionGroups;
  final bool isShopOpen;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    required this.shopId,
    required this.shopName,
    this.categoryId,
    this.categoryName,
    this.optionGroups = const [],
    this.isShopOpen = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int sId = json['shopId'] ?? json['ShopId'] ?? 0;
    String sName = (json['shopName'] ?? json['ShopName'] ?? '').toString();

    if (json['shop'] != null && json['shop'] is Map<String, dynamic>) {
      if (sId <= 0) sId = json['shop']['id'] ?? json['shop']['Id'] ?? 0;
      if (sName.isEmpty) sName = json['shop']['name'] ?? json['shop']['Name'] ?? '';
    }
    if (sName.isEmpty) sName = 'Quán ăn Làng Food';

    List<ProductOptionGroupModel> parsedOptionGroups = [];
    var rawGroups = json['optionGroups'] ?? json['OptionGroups'];
    if (rawGroups is List) {
      parsedOptionGroups = rawGroups
          .map((g) => ProductOptionGroupModel.fromJson(g as Map<String, dynamic>))
          .toList();
    }

    return ProductModel(
      id: json['id'] ?? json['Id'] ?? 0,
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      description: json['description'] ?? json['Description'],
      price: (json['price'] ?? json['Price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? json['ImageUrl'],
      isAvailable: json['isAvailable'] ?? json['IsAvailable'] ?? true,
      shopId: sId,
      shopName: sName,
      categoryId: json['categoryId'] ?? json['CategoryId'],
      categoryName: json['categoryName'] ?? json['CategoryName'],
      optionGroups: parsedOptionGroups,
      isShopOpen: json['isShopOpen'] ?? json['IsShopOpen'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'shopId': shopId,
      'shopName': shopName,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }
}
