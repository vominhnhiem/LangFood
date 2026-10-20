import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  String? note;
  String? selectedOptionsJson;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.note,
    this.selectedOptionsJson,
  });

  double get totalPrice {
    return product.price * quantity;
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] ?? json['Product'] ?? {}),
      quantity: json['quantity'] ?? json['Quantity'] ?? 1,
      note: json['note'] ?? json['Note'],
      selectedOptionsJson: json['selectedOptionsJson'] ?? json['SelectedOptionsJson'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'note': note,
      'selectedOptionsJson': selectedOptionsJson,
    };
  }
}
