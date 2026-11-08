import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrderService {
  Future<List<OrderModel>> getBuyerOrders(String buyerId) async {
    final data = ApiClient.decodeResponse(
      await ApiClient.get('api/Orders/buyer/$buyerId'),
    ) as List;
    return data
        .map((row) => OrderModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> cancelOrder(int orderId) async {
    ApiClient.decodeResponse(await ApiClient.delete('api/Orders/$orderId'));
  }

  Future<OrderModel?> createOrder(OrderModel order) async {
    if (order.buyerId.isEmpty ||
        order.shopId <= 0 ||
        order.orderItems.isEmpty) {
      throw Exception('Thông tin đơn hàng không hợp lệ.');
    }
    late final dynamic response;
    try {
      response = await ApiClient.post('api/Orders', body: order.toJson());
    } catch (_) {
      throw const OrderSubmissionUncertain(
        'Mất kết nối khi gửi đơn, chưa xác định máy chủ đã nhận hay chưa.',
      );
    }
    if (response.statusCode >= 500) {
      throw const OrderSubmissionUncertain('Máy chủ gặp lỗi khi xử lý đơn.');
    }
    final data = ApiClient.decodeResponse(response);
    try {
      final created = OrderModel.fromJson(Map<String, dynamic>.from(data));
      if (created.id == null || created.id! <= 0) throw const FormatException();
      return created;
    } catch (_) {
      throw const OrderSubmissionUncertain('Máy chủ chưa trả mã đơn hợp lệ.');
    }
  }

  // Lấy danh sách đơn hàng dành cho Shipper
  Future<List<OrderModel>> getOrdersForShipper(int shipperId) async {
    try {
      final response = await ApiClient.get(
        'api/Orders/available-for-shipper/$shipperId',
      );
      if (response.statusCode == 200) {
        final List list = jsonDecode(utf8.decode(response.bodyBytes));
        return list.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi lấy danh sách đơn hàng (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('OrderService.getOrdersForShipper error: $e');
      rethrow;
    }
  }

  Future<OrderModel?> getOrderById(int orderId) async {
    final response = await ApiClient.get('api/Orders/$orderId');
    if (response.statusCode == 404) return null;
    final data = ApiClient.decodeResponse(response);
    return OrderModel.fromJson(Map<String, dynamic>.from(data));
  }

  // Lấy danh sách đơn hàng của Quán ăn
  Future<List<OrderModel>> getOrdersByShop(int shopId) async {
    final orders = ApiClient.decodeResponse(
      await ApiClient.get('api/Orders/shop/$shopId'),
    ) as List;
    return orders.map((json) => OrderModel.fromJson(json)).toList();
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

  Future<Map<String, dynamic>> getShopPickup(int shopId) async {
    return ApiClient.decodeResponse(
      await ApiClient.get('api/Shops/$shopId/pickup'),
    ) as Map<String, dynamic>;
  }

  Future<bool> confirmPickup(
    int orderId,
    int shipperId, {
    double? lat,
    double? lng,
  }) async {
    String url = 'api/Orders/$orderId/pickup?shipperId=$shipperId';
    if (lat != null && lng != null) {
      url += '&lat=$lat&lng=$lng';
    }
    final response = await ApiClient.put(url);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    ApiClient.decodeResponse(response);
    return false;
  }

  Future<bool> acceptOrder(int orderId, int shipperId) async {
    try {
      final response = await ApiClient.put(
        'api/Orders/$orderId/claim?shipperId=$shipperId',
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        String msg = 'Không thể nhận đơn hàng này';
        try {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
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
  Future<bool> completeOrder(int orderId, {double? lat, double? lng}) async {
    try {
      String url = 'api/Orders/complete/$orderId';
      if (lat != null && lng != null) {
        url += '?lat=$lat&lng=$lng';
      }
      final response = await ApiClient.put(url);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      ApiClient.decodeResponse(response);
      return false;
    } catch (e) {
      debugPrint('OrderService.completeOrder error: $e');
      rethrow;
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
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('OrderService.getShipperLocation error: $e');
      return null;
    }
  }
}

class OrderSubmissionUncertain implements Exception {
  final String message;
  const OrderSubmissionUncertain(this.message);
  @override
  String toString() => message;
}
