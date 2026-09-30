import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/order_test_model.dart';

class OrderTestService {
  Future<OrderTestModel?> createOrderTest(OrderTestModel order) async {
    try {
      final response = await ApiClient.post('api/OrderTests', body: order.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return OrderTestModel.fromJson(data);
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Không thể tạo đơn test (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('OrderTestService.createOrderTest error: $e');
      rethrow;
    }
  }

  Future<List<OrderTestModel>> getAvailableOrderTests([int? shipperId]) async {
    try {
      final query = shipperId != null ? {'shipperId': shipperId.toString()} : null;
      final response = await ApiClient.get('api/OrderTests/available', queryParams: query);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((json) => OrderTestModel.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi lấy danh sách đơn test (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('OrderTestService.getAvailableOrderTests error: $e');
      return [];
    }
  }

  Future<bool> acceptOrderTest(int orderId, int shipperId) async {
    try {
      final response = await ApiClient.put('api/OrderTests/accept/$orderId?shipperId=$shipperId');
      if (response.statusCode == 200) {
        return true;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Không thể nhận đơn test');
      }
    } catch (e) {
      debugPrint('OrderTestService.acceptOrderTest error: $e');
      rethrow;
    }
  }
}
