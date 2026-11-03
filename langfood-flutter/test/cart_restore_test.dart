import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langfood_flutter/data/models/cart_item_model.dart';
import 'package:langfood_flutter/data/models/product_model.dart';
import 'package:langfood_flutter/data/services/cart_service.dart';
import 'package:langfood_flutter/providers/cart_provider.dart';

ProductModel food(int id) => ProductModel(
  id: id,
  name: 'Món $id',
  price: 10000,
  shopId: 1,
  shopName: 'Quán thật',
);
CartItemModel item(int id, {int quantity = 1}) =>
    CartItemModel(product: food(id), quantity: quantity);
List<CartItemModel> clone(Iterable<CartItemModel> rows) =>
    rows.map((e) => CartItemModel.fromJson(e.toJson())).toList();

class CartApi extends CartService {
  final Map<String, List<CartItemModel>> remote = {};
  bool failLoad = false;
  bool failWrites = false;
  int writes = 0;
  @override
  Future<List<CartItemModel>> getCart(String userId) async {
    if (failLoad) throw Exception('offline');
    return clone(remote[userId] ?? []);
  }

  @override
  Future<void> replaceCart(String userId, List<CartItemModel> rows) async {
    writes++;
    if (failWrites) throw Exception('offline');
    remote[userId] = clone(rows);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('server empty cart replaces previous account and logout preserves saved account cart', () async {
    final api = CartApi()..remote['alice'] = [item(1, quantity: 3)];
    final cart = CartProvider(service: api);
    await cart.loadCartFromServer('alice');
    expect(cart.totalItemsCount, 3);
    await cart.loadCartFromServer('bob');
    expect(cart.items, isEmpty);
    await cart.loadCartFromServer('alice');
    expect(cart.totalItemsCount, 3);
    await cart.loadCartFromServer(null);
    expect(cart.items, isEmpty);
    expect(api.remote['alice']!.single.quantity, 3);
    cart.dispose();
  });
  test(
    'guest cart persists across restart and merges into account only once',
    () async {
      final api = CartApi()..remote['alice'] = [item(2)];
      final guest = CartProvider(service: api);
      await guest.loadCartFromServer(null);
      guest.addToCart(product: food(1), quantity: 2);
      await guest.flush();
      guest.dispose();
      final cart = CartProvider(service: api);
      await cart.loadCartFromServer(null);
      expect(cart.totalItemsCount, 2);
      await cart.loadCartFromServer('alice');
      await cart.flush();
      expect(cart.totalItemsCount, 3);
      await cart.loadCartFromServer('alice');
      expect(cart.totalItemsCount, 3);
      cart.dispose();
    },
  );
  test(
    'rapid quantity edits and removing one variant preserve the other',
    () async {
      final api = CartApi();
      final cart = CartProvider(service: api);
      await cart.loadCartFromServer('alice');
      cart.addToCart(
        product: food(1),
        note: 'Ít cay',
        selectedOptionsJson: 'Trứng',
        unitPrice: 15000,
      );
      cart.addToCart(product: food(1), note: 'Cay', unitPrice: 10000);
      final first = cart.items.first;
      cart.updateQuantity(first, 1);
      cart.updateQuantity(first, 1);
      cart.removeItem(cart.items.last);
      await cart.flush();
      expect(api.remote['alice']!.length, 1);
      expect(api.remote['alice']!.single.quantity, 3);
      expect(cart.totalAmount, 45000);
      expect(cart.isSyncing, isFalse);
      final restored = CartItemModel.fromJson({
        'product': food(1).toJson(),
        'quantity': 3,
        'selectedOptions': first.serverOptions,
        'note': first.note,
      });
      expect(restored.totalPrice, 45000);
      expect(restored.selectedOptionsSummary, 'Trứng');
      cart.dispose();
    },
  );
  test(
    'failed writes survive restart and retry sends the saved local state',
    () async {
      final api = CartApi()..failWrites = true;
      final cart = CartProvider(service: api);
      await cart.loadCartFromServer('alice');
      cart.addToCart(product: food(1), quantity: 2);
      await cart.flush();
      expect(cart.syncError, isNotNull);
      cart.dispose();
      final restarted = CartProvider(service: api);
      await restarted.loadCartFromServer('alice');
      await restarted.flush();
      expect(restarted.totalItemsCount, 2);
      api.failWrites = false;
      await restarted.retrySync();
      expect(restarted.syncError, isNull);
      expect(api.remote['alice']!.single.quantity, 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('CART_V2_alice_dirty'), isFalse);
      expect(
        jsonDecode(prefs.getString('CART_V2_alice')!) as List,
        hasLength(1),
      );
      restarted.dispose();
    },
  );
  test(
    'failed initial restore never replaces an unknown remote cart',
    () async {
      final api = CartApi()..remote['alice'] = [item(2)];
      final cart = CartProvider(service: api);
      await cart.loadCartFromServer(null);
      cart.addToCart(product: food(1));
      await cart.flush();
      api.failLoad = true;
      await cart.loadCartFromServer('alice');
      expect(cart.canEdit, isFalse);
      expect(api.writes, 0);
      api.failLoad = false;
      await cart.retrySync();
      await cart.flush();
      expect(cart.canEdit, isTrue);
      expect(cart.totalItemsCount, 2);
      expect(api.remote['alice'], hasLength(2));
      cart.dispose();
    },
  );
}
