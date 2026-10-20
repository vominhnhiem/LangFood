import 'dart:convert';
import '../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/product_option_model.dart';
import '../models/shop_model.dart';

class ProductService {
  Future<List<CategoryModel>> getCategories() async {
    final response = await ApiClient.get('api/Categories');
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    }
    throw Exception('Không thể tải danh mục món ăn');
  }

  Future<List<ProductModel>> getProducts({int? categoryId, String? search}) async {
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

  Future<List<ProductOptionGroupModel>> getProductOptions(int productId) async {
    try {
      final response = await ApiClient.get('api/ProductOptions/product/$productId');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => ProductOptionGroupModel.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }
}
