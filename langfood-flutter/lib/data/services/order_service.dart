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

  // Shipper bấm Nhận đơn hàng
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
}
