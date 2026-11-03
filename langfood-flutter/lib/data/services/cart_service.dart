import '../../core/network/api_client.dart';
import '../models/cart_item_model.dart';
import 'product_service.dart';

class CartService {
  Future<List<CartItemModel>> getCart(String userId) async {
    final data = ApiClient.decodeResponse(
      await ApiClient.get('api/Cart/$userId'),
    ) as List;
    final items = data
        .map((row) => CartItemModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
    // Cart API includes Product but omits its Shop navigation property.
    final missingShops = items
        .where(
          (item) =>
              item.product.shopName == 'Quán ăn Làng Food' &&
              item.product.shopId > 0,
        )
        .map((item) => item.product.shopId)
        .toSet();
    final names = <int, String>{};
    await Future.wait(
      missingShops.map((shopId) async {
        try {
          names[shopId] = (await ProductService().getShopById(shopId)).name;
        } catch (_) {
          names[shopId] = 'Quán #$shopId';
        }
      }),
    );
    return items
        .map(
          (item) => names.containsKey(item.product.shopId)
              ? CartItemModel(
                  product: item.product.copyWith(
                    shopName: names[item.product.shopId],
                  ),
                  quantity: item.quantity,
                  note: item.note,
                  selectedOptionsJson: item.selectedOptionsJson,
                  unitPrice: item.unitPrice,
                )
              : item,
        )
        .toList();
  }

  Future<void> addToCart({
    required String userId,
    required int productId,
    required int quantity,
    String? note,
    String? selectedOptions,
  }) async {
    ApiClient.decodeResponse(
      await ApiClient.post(
        'api/Cart',
        queryParams: {
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
          'note': note ?? '',
          'selectedOptions': selectedOptions ?? '',
        },
      ),
    );
  }

  Future<void> removeFromCart(String userId, int productId) async {
    ApiClient.decodeResponse(
      await ApiClient.delete('api/Cart/$userId/$productId'),
    );
  }

  Future<void> clearCart(String userId) async {
    ApiClient.decodeResponse(await ApiClient.delete('api/Cart/$userId'));
  }

  // API deletes by product only, so replace the snapshot to preserve variants.
  Future<void> replaceCart(String userId, List<CartItemModel> items) async {
    await clearCart(userId);
    for (final item in items) {
      await addToCart(
        userId: userId,
        productId: item.product.id,
        quantity: item.quantity,
        note: item.note,
        selectedOptions: item.serverOptions,
      );
    }
  }
}
