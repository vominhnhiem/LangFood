import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  String? note;
  String? selectedOptionsJson;
  double? unitPrice;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.note,
    this.selectedOptionsJson,
    this.unitPrice,
  });

  double get effectiveUnitPrice => unitPrice ?? product.price;

  double get totalPrice {
    return effectiveUnitPrice * quantity;
  }

  String get selectedOptionsSummary => note ?? '';

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final prod = ProductModel.fromJson(json['product'] ?? json['Product'] ?? {});
    final double? parsedPrice = (json['unitPrice'] ?? json['UnitPrice'] ?? json['price'] ?? json['Price'])?.toDouble();
    return CartItemModel(
      product: parsedPrice != null ? prod.copyWith(price: parsedPrice) : prod,
      quantity: json['quantity'] ?? json['Quantity'] ?? 1,
      note: json['note'] ?? json['Note'],
      selectedOptionsJson: json['selectedOptionsJson'] ?? json['SelectedOptionsJson'],
      unitPrice: parsedPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.copyWith(price: effectiveUnitPrice).toJson(),
      'quantity': quantity,
      'note': note,
      'selectedOptionsJson': selectedOptionsJson,
      'unitPrice': effectiveUnitPrice,
    };
  }
}
