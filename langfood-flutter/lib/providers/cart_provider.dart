import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import '../data/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  List<CartItemModel> _items = [];

  List<CartItemModel> get items => _items;

  int get totalItemsCount {
    int count = 0;
    for (var item in _items) {
      count += item.quantity;
    }
    return count;
  }

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  /// Groups items by shopId, matching CartAdapter.java in Android
  Map<int, List<CartItemModel>> get itemsByShop {
    final Map<int, List<CartItemModel>> map = {};
    for (var item in _items) {
      int sId = item.product.shopId > 0 ? item.product.shopId : 999;
      if (!map.containsKey(sId)) {
        map[sId] = [];
      }
      map[sId]!.add(item);
    }
    return map;
  }

  String getShopName(int shopId) {
    for (var item in _items) {
      if (item.product.shopId == shopId && item.product.shopName.isNotEmpty) {
        return item.product.shopName;
      }
    }
    return 'Quán ăn Làng Food';
  }

  double getShopSubtotal(int shopId) {
    double sub = 0;
    final shopItems = itemsByShop[shopId] ?? [];
    for (var item in shopItems) {
      sub += item.totalPrice;
    }
    return sub;
  }

  Future<void> loadCartFromServer(String? userId) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final serverItems = await _cartService.getCart(userId);
      if (serverItems.isNotEmpty) {
        _items = serverItems;
        notifyListeners();
      }
    } catch (_) {}
  }

  void addToCart({
    required ProductModel product,
    int quantity = 1,
    String? note,
    String? selectedOptionsJson,
    String? userId,
  }) {
    // Check if identical item (same product, same note, same options) exists
    bool exists = false;
    for (var item in _items) {
      bool sameProduct = item.product.id == product.id;
      bool sameNote = (note == null || note.trim().isEmpty)
          ? (item.note == null || item.note!.trim().isEmpty)
          : (item.note == note);
      bool sameOptions = (selectedOptionsJson == null || selectedOptionsJson.trim().isEmpty)
          ? (item.selectedOptionsJson == null || item.selectedOptionsJson!.trim().isEmpty)
          : (item.selectedOptionsJson == selectedOptionsJson);

      if (sameProduct && sameNote && sameOptions) {
        item.quantity += quantity;
        exists = true;
        break;
      }
    }

    if (!exists) {
      _items.add(CartItemModel(
        product: product,
        quantity: quantity,
        note: note,
        selectedOptionsJson: selectedOptionsJson,
      ));
    }

    notifyListeners();

    // Async sync to server
    if (userId != null && userId.isNotEmpty) {
      _cartService
          .addToCart(
            userId: userId,
            productId: product.id,
            quantity: quantity,
            note: note,
            selectedOptions: selectedOptionsJson,
          )
          .catchError((_) {});
    }
  }

  void updateQuantity(CartItemModel item, int delta, [String? userId]) {
    final index = _items.indexOf(item);
    if (index != -1) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        final removed = _items.removeAt(index);
        if (userId != null && userId.isNotEmpty) {
          _cartService.removeFromCart(userId, removed.product.id).catchError((_) {});
        }
      }
      notifyListeners();
    }
  }

  void removeItem(CartItemModel item, [String? userId]) {
    _items.remove(item);
    notifyListeners();
    if (userId != null && userId.isNotEmpty) {
      _cartService.removeFromCart(userId, item.product.id).catchError((_) {});
    }
  }

  void clearCart([String? userId]) {
    _items.clear();
    notifyListeners();
    if (userId != null && userId.isNotEmpty) {
      _cartService.clearCart(userId).catchError((_) {});
    }
  }
}
