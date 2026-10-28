import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderService {
  // Tạo đơn hàng mới đẩy lên SQL Database Backend
  Future<OrderModel?> createOrder(OrderModel order) async {
    try {
      final response = await ApiClient.post('api/Orders', body: order.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return OrderModel.fromJson(data);
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Không thể tạo đơn hàng (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('OrderService.createOrder error: $e');
      rethrow;
    }
  }

  // Lấy danh sách đơn hàng dành cho Shipper
  Future<List<OrderModel>> getOrdersForShipper(int shipperId) async {
    try {
      final response = await ApiClient.get('api/Orders/available-for-shipper/$shipperId');
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi lấy danh sách đơn hàng (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('OrderService.getOrdersForShipper error: $e');
      return [];
    }
  }

  // Lấy chi tiết đơn hàng theo ID (Dùng cho khách hàng theo dõi realtime)
  Future<OrderModel?> getOrderById(int orderId) async {
    try {
      final response = await ApiClient.get('api/Orders/$orderId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderModel.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('OrderService.getOrderById error: $e');
      return null;
    }
  }

  // Lấy danh sách đơn hàng của Quán ăn
  Future<List<OrderModel>> getOrdersByShop(int shopId) async {
    try {
      final response = await ApiClient.get('api/Orders/shop/$shopId');
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((json) => OrderModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('OrderService.getOrdersByShop error: $e');
      return [];
    }
  }

  // Quán ăn xác nhận đơn hàng & Bắt đầu nấu (Chuyển sang "Preparing")
  Future<bool> shopAcceptOrder(int orderId) async {
    try {
      final response = await ApiClient.put('api/Orders/shop-accept/$orderId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('OrderService.shopAcceptOrder error: $e');
      return false;
    }
  }

  // Quán ăn báo đã nấu xong món (Chuyển sang "Ready", sẵn sàng cho Shipper nhận)
  Future<bool> shopReadyOrder(int orderId) async {
    try {
      final response = await ApiClient.put('api/Orders/shop-ready/$orderId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('OrderService.shopReadyOrder error: $e');
      return false;
    }
  }

  // Shipper bấm Nhận đơn hàng (Chuyển sang "Delivering")
  Future<bool> acceptOrder(int orderId, int shipperId) async {
    try {
      final response = await ApiClient.put('api/Orders/accept/$orderId?shipperId=$shipperId');
      if (response.statusCode == 200) {
        return true;
      } else {
        String msg = 'Không thể nhận đơn hàng này';
        try {
          final data = jsonDecode(response.body);
          if (data is String) msg = data;
          if (data is Map && data['message'] != null) msg = data['message'];
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('OrderService.acceptOrder error: $e');
      rethrow;
    }
  }

  // Shipper hoàn thành đơn hàng (Chuyển sang "Completed")
  Future<bool> completeOrder(int orderId) async {
    try {
      final response = await ApiClient.put('api/Orders/complete/$orderId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('OrderService.completeOrder error: $e');
      return false;
    }
  }

  // Shipper cập nhật vị trí GPS thực tế cho đơn hàng
  Future<bool> updateShipperLocation({
    required int orderId,
    required double latitude,
    required double longitude,
    double? bearing,
    double? speed,
    double? speedKmh,
    double? headingDegree,
    String? statusNote,
    int? shipperId,
  }) async {
    try {
      final response = await ApiClient.post(
        'api/Orders/$orderId/location',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'bearing': headingDegree ?? bearing ?? 0.0,
          'speed': speedKmh ?? speed ?? 0.0,
          'shipperId': shipperId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('OrderService.updateShipperLocation error: $e');
      return false;
    }
  }

  // Khách hàng / App lấy vị trí thực tế hiện tại của Shipper
  Future<Map<String, dynamic>?> getShipperLocation(int orderId) async {
    try {
      final response = await ApiClient.get('api/Orders/$orderId/location');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('OrderService.getShipperLocation error: $e');
      return null;
    }
  }
}
