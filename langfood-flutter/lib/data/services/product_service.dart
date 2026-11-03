import 'dart:convert';

import '../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_option_model.dart';
import '../models/shop_model.dart';

class ProductService {
  Future<void> saveProduct({
    ProductModel? existing,
    required int shopId,
    required int categoryId,
    required String name,
    required double price,
    required String description,
    String? imageUrl,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    if (shopId <= 0 || name.trim().isEmpty || !price.isFinite || price <= 0) {
      throw Exception('Thông tin món ăn không hợp lệ.');
    }
    if (existing != null && existing.shopId != shopId) {
      throw Exception('Món không thuộc quán hiện tại.');
    }
    if (existing == null && imageBytes != null) {
      if (imageBytes.length > 5 * 1024 * 1024) {
        throw Exception('Ảnh không được vượt quá 5 MB.');
      }
      ApiClient.decodeResponse(
        await ApiClient.upload(
          'api/Products/upload',
          fields: {
            'name': name.trim(),
            'price': price.toStringAsFixed(0),
            'description': description.trim(),
            'shopId': shopId.toString(),
            'categoryId': categoryId.toString(),
          },
          bytes: imageBytes,
          filename: imageName ?? 'food.jpg',
        ),
      );
    } else {
      final url = imageUrl?.trim() ?? existing?.imageUrl ?? '';
      if (url.isEmpty) throw Exception('Vui lòng chọn ảnh hoặc nhập URL ảnh.');
      final body = <String, dynamic>{
        if (existing != null) 'id': existing.id,
        'shopId': shopId,
        'categoryId': categoryId,
        'name': name.trim(),
        'price': price,
        'description': description.trim(),
        'imageUrl': url,
      };
      ApiClient.decodeResponse(
        existing == null
            ? await ApiClient.post('api/Products', body: body)
            : await ApiClient.put('api/Products/${existing.id}', body: body),
      );
    }
  }

  Future<void> deleteProduct(int id) async {
    ApiClient.decodeResponse(await ApiClient.delete('api/Products/$id'));
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await ApiClient.get('api/Categories');
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    }
    throw Exception('Không thể tải danh mục món ăn');
  }

  Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? search,
  }) async {
    final Map<String, dynamic> params = {};
    if (categoryId != null && categoryId > 0) {
      params['categoryId'] = categoryId;
    }
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    final response = await ApiClient.get('api/Products', queryParams: params);
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => ProductModel.fromJson(json)).toList();
    }
    throw Exception('Không thể tải danh sách món ăn');
  }

  Future<ProductModel> getProductById(int id) async {
    final response = await ApiClient.get('api/Products/$id');
    if (response.statusCode == 200) {
      return ProductModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Không tìm thấy món ăn');
  }

  /// Lấy thông tin chi tiết của Quán ăn theo ID (GET api/Shops/{id})
  Future<ShopModel> getShopById(int shopId) async {
    final response = await ApiClient.get('api/Shops/$shopId');
    if (response.statusCode == 200) {
      return ShopModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Không thể tải thông tin quán ăn');
  }

  /// Lấy toàn bộ thực đơn món ăn của Quán ăn (GET api/Products/shop/{shopId})
  Future<List<ProductModel>> getProductsByShop(int shopId) async {
    final response = await ApiClient.get('api/Products/shop/$shopId');
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => ProductModel.fromJson(json)).toList();
    }
    throw Exception('Không thể tải thực đơn quán ăn');
  }

  Future<ProductModel> createProduct(Map<String, dynamic> productData) async {
    final response = await ApiClient.post('api/Products', body: productData);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProductModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    final error = jsonDecode(utf8.decode(response.bodyBytes));
    throw Exception(error['message'] ?? 'Không thể tạo món ăn mới');
  }

  Future<List<ProductOptionGroupModel>> getProductOptions(int productId) async {
    try {
      final response = await ApiClient.get(
        'api/ProductOptions/product/$productId',
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data
            .map((json) => ProductOptionGroupModel.fromJson(json))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
