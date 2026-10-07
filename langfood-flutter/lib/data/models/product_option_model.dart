class ProductOptionModel {
  final int id;
  final int? groupId;
  final String name;
  final double price;
  bool isSelected;

  ProductOptionModel({
    required this.id,
    this.groupId,
    required this.name,
    this.price = 0.0,
    this.isSelected = false,
  });

  factory ProductOptionModel.fromJson(Map<String, dynamic> json) {
    return ProductOptionModel(
      id: json['id'] ?? json['Id'] ?? 0,
      groupId: json['groupId'] ?? json['GroupId'],
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      price: (json['price'] ?? json['Price'] ?? 0).toDouble(),
      isSelected: json['isSelected'] ?? json['IsSelected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'name': name,
      'price': price,
    };
  }
}

class ProductOptionGroupModel {
  final int id;
  final int? productId;
  final String name;
  final bool isMultiple;
  final List<ProductOptionModel> options;

  ProductOptionGroupModel({
    required this.id,
    this.productId,
    required this.name,
    this.isMultiple = false,
    this.options = const [],
  });

  factory ProductOptionGroupModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'] ?? json['Options'];
    List<ProductOptionModel> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions
          .map((opt) => ProductOptionModel.fromJson(opt as Map<String, dynamic>))
          .toList();
    }

    return ProductOptionGroupModel(
      id: json['id'] ?? json['Id'] ?? 0,
      productId: json['productId'] ?? json['ProductId'],
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      isMultiple: json['isMultiple'] ?? json['IsMultiple'] ?? false,
      options: parsedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'isMultiple': isMultiple,
      'options': options.map((e) => e.toJson()).toList(),
    };
  }
}
