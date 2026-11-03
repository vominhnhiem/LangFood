import 'cart_item_model.dart';

/// A frozen selection: later cart changes must not change an order in review.
class CheckoutSelection {
  final List<CartItemModel> items;
  final Map<int, String> shopNotes;

  CheckoutSelection(
    Iterable<CartItemModel> source, {
    Map<int, String> shopNotes = const {},
  }) : items = List.unmodifiable(
         source.map((item) => CartItemModel.fromJson(item.toJson())),
       ),
       shopNotes = Map.unmodifiable(shopNotes);

  Map<int, List<CartItemModel>> get byShop {
    final result = <int, List<CartItemModel>>{};
    for (final item in items) {
      (result[item.product.shopId] ??= []).add(item);
    }
    return result;
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get quantity => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isValid =>
      items.isNotEmpty &&
      items.every(
        (item) =>
            item.product.id > 0 &&
            item.product.shopId > 0 &&
            item.quantity > 0 &&
            item.effectiveUnitPrice.isFinite &&
            item.effectiveUnitPrice > 0,
      );
}
