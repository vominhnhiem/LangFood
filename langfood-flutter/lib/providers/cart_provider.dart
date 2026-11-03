import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/cart_item_model.dart';
import '../data/models/product_model.dart';
import '../data/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _service;
  List<CartItemModel> _items = [];
  Future<void> _writes = Future.value();
  String? _currentUserId;
  String? _requestedUserId;
  bool _bound = false;
  bool _disposed = false;
  int _epoch = 0;
  int _queuedWrites = 0;
  bool canEdit = true;
  String? _pendingGuestUser;
  List<CartItemModel> _pendingGuest = [];
  bool isLoading = false;
  bool isSyncing = false;
  String? syncError;
  CartProvider({CartService? service}) : _service = service ?? CartService();

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get totalItemsCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  String _key(String? userId) => 'CART_V2_${userId ?? 'guest'}';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Map<int, List<CartItemModel>> get itemsByShop {
    final result = <int, List<CartItemModel>>{};
    for (final item in _items) {
      (result[item.product.shopId] ??= []).add(item);
    }
    return result;
  }

  String getShopName(int shopId) {
    final names = _items
        .where((item) => item.product.shopId == shopId)
        .map((item) => item.product.shopName)
        .where((s) => s.isNotEmpty);
    return names.isEmpty ? 'Quán #$shopId' : names.first;
  }

  double getShopSubtotal(int shopId) => (itemsByShop[shopId] ?? []).fold(
    0.0,
    (sum, item) => sum + item.totalPrice,
  );
  List<CartItemModel> _clone(Iterable<CartItemModel> items) =>
      items.map((e) => CartItemModel.fromJson(e.toJson())).toList();

  void bindUser(String? userId) {
    if (_bound && _requestedUserId == userId) return;
    _bound = true;
    _requestedUserId = userId;
    final epoch = ++_epoch;
    scheduleMicrotask(() => _activate(userId, epoch));
  }

  Future<void> loadCartFromServer(String? userId) async {
    _bound = true;
    _requestedUserId = userId;
    await _activate(userId, ++_epoch);
  }

  Future<void> _activate(String? userId, int epoch) async {
    if (_disposed || epoch != _epoch) return;
    final guest = _currentUserId == null && userId != null
        ? _clone(_items)
        : (_pendingGuestUser == userId
              ? _clone(_pendingGuest)
              : <CartItemModel>[]);
    isLoading = true;
    _notify();
    await _writes;
    if (_disposed || epoch != _epoch) return;
    _currentUserId = userId;
    canEdit = true;
    isSyncing = false;
    _items = [];
    syncError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key(userId));
      final cached = saved == null
          ? <CartItemModel>[]
          : (jsonDecode(saved) as List)
                .map(
                  (e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
      var dirty = prefs.getBool('${_key(userId)}_dirty') ?? false;
      var restored = cached;
      if (userId != null && !dirty) {
        try {
          restored = await _service.getCart(userId);
        } catch (_) {
          canEdit = false;
          _pendingGuestUser = userId;
          _pendingGuest = guest;
          _items = cached.isNotEmpty ? cached : guest;
          syncError = 'Chưa tải được giỏ từ máy chủ. Bản lưu được giữ nguyên; hãy thử tải lại trước khi thay đổi.';
          return;
        }
      }
      if (_disposed || epoch != _epoch) return;
      _items = restored;
      for (final item in guest) {
        _merge(item);
      }
      if (guest.isNotEmpty) {
        dirty = true;
        await prefs.remove(_key(null));
      }
      _pendingGuest = [];
      _pendingGuestUser = null;
      await prefs.setString(
        _key(userId),
        jsonEncode(_items.map((e) => e.toJson()).toList()),
      );
      if (dirty) _queueSave();
    } catch (e) {
      syncError = 'Không khôi phục được giỏ hàng: $e';
    } finally {
      if (!_disposed && epoch == _epoch) {
        isLoading = false;
        _notify();
      }
    }
  }

  void _merge(CartItemModel item) {
    final index = _items.indexWhere(
      (e) =>
          e.product.id == item.product.id &&
          e.effectiveUnitPrice == item.effectiveUnitPrice &&
          (e.note ?? '') == (item.note ?? '') &&
          e.selectedOptionsSummary == item.selectedOptionsSummary,
    );
    if (index < 0) {
      _items.add(item);
    } else {
      _items[index].quantity += item.quantity;
    }
  }

  void addToCart({
    required ProductModel product,
    int quantity = 1,
    String? note,
    String? selectedOptionsJson,
    double? unitPrice,
    String? userId,
  }) {
    if (isLoading || !canEdit || quantity <= 0 || product.id <= 0) return;
    _merge(
      CartItemModel(
        product: product,
        quantity: quantity,
        note: note,
        selectedOptionsJson: selectedOptionsJson,
        unitPrice: unitPrice ?? product.price,
      ),
    );
    _queueSave();
  }

  void updateQuantity(CartItemModel item, int delta, [String? userId]) {
    if (isLoading || !canEdit || !_items.contains(item)) return;
    item.quantity += delta;
    if (item.quantity <= 0) _items.remove(item);
    _queueSave();
  }

  void removeItem(CartItemModel item, [String? userId]) {
    if (isLoading || !canEdit) return;
    _items.remove(item);
    _queueSave();
  }

  void clearCart([String? userId]) {
    if (isLoading || !canEdit) return;
    _items.clear();
    _queueSave();
  }

  void _queueSave() {
    final snapshot = _clone(_items);
    final userId = _currentUserId;
    final epoch = _epoch;
    _queuedWrites++;
    isSyncing = true;
    syncError = null;
    _notify();
    _writes = _writes
        .then((_) async {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              _key(userId),
              jsonEncode(snapshot.map((e) => e.toJson()).toList()),
            );
            if (userId != null) {
              await prefs.setBool('${_key(userId)}_dirty', true);
              await _service.replaceCart(userId, snapshot);
              await prefs.setBool('${_key(userId)}_dirty', false);
            }
            if (epoch == _epoch) syncError = null;
          } catch (e) {
            if (epoch == _epoch)
              syncError =
                  'Giỏ đã lưu trên máy nhưng chưa đồng bộ: ${e.toString().replaceFirst('Exception: ', '')}';
          }
        })
        .then((_) {
          _queuedWrites--;
          if (epoch == _epoch) {
            isSyncing = _queuedWrites > 0;
            _notify();
          }
        });
  }

  Future<void> flush() async {
    await _writes;
  }

  Future<void> retrySync() async {
    if (!canEdit) {
      await loadCartFromServer(_currentUserId);
      return;
    }
    _queueSave();
    await flush();
  }
}
