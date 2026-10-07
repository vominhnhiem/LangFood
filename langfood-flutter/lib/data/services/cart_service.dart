import 'dart:convert';
import '../../core/network/api_client.dart';
import '../models/cart_item_model.dart';

class CartService {
  Future<List<CartItemModel>> getCart(String userId) async {
    final response = await ApiClient.get('api/Cart/$userId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => CartItemModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> addToCart({
    required String userId,
    required int productId,
    required int quantity,
    String? note,
    String? selectedOptions,
  }) async {
    await ApiClient.post(
      'api/Cart',
      queryParams: {
        'userId': userId,
        'productId': productId,
        'quantity': quantity,
        'note': note ?? '',
        'selectedOptions': selectedOptions ?? '',
      },
    );
  }

  Future<void> removeFromCart(String userId, int productId) async {
    await ApiClient.delete('api/Cart/$userId/$productId');
  }

  Future<void> clearCart(String userId) async {
    await ApiClient.delete('api/Cart/$userId');
  }
}
