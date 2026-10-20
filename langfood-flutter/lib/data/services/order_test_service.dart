import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/order_test_model.dart';

class OrderTestService {
  // Kho lưu trữ đơn hàng giả lập thời gian thực (shared across all screens/roles)
  static final List<OrderTestModel> _inMemoryOrders = [
    OrderTestModel(
      id: 101,
      customerName: 'Nguyễn Văn Nhiệm (KTX B)',
      phone: '0901234567',
      deliveryAddress: 'Sảnh G - Tòa BA2 KTX Khu B, ĐHQG',
      latitude: 10.8751,
      longitude: 106.7997,
      totalAmount: 48000,
      status: 'Ready',
      createdAt: DateTime.now()
          .subtract(const Duration(minutes: 3))
          .toIso8601String(),
    ),
  ];

  static final ValueNotifier<List<OrderTestModel>> ordersNotifier =
      ValueNotifier<List<OrderTestModel>>(List.unmodifiable(_inMemoryOrders));

  static void _notifyChange() {
    ordersNotifier.value = List.unmodifiable(_inMemoryOrders);
  }

  Future<OrderTestModel?> createOrderTest(OrderTestModel order) async {
    final simulated = OrderTestModel(
      id: order.id ?? (DateTime.now().millisecondsSinceEpoch % 10000),
      customerName: order.customerName,
      phone: order.phone,
      deliveryAddress: order.deliveryAddress,
      latitude: order.latitude,
      longitude: order.longitude,
      totalAmount: order.totalAmount,
      status: order.status.isNotEmpty ? order.status : 'Ready',
      createdAt: order.createdAt ?? DateTime.now().toIso8601String(),
    );
    _inMemoryOrders.insert(0, simulated);
    _notifyChange();

    try {
      final response =
          await ApiClient.post('api/OrderTests', body: order.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final created = OrderTestModel.fromJson(data);
        _inMemoryOrders[0] = created;
        _notifyChange();
        return created;
      } else {
        final err = jsonDecode(response.body);
        throw Exception(
            err['message'] ?? 'Không thể tạo đơn test (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('OrderTestService.createOrderTest error: $e');
      rethrow;
    }
  }

  Future<List<OrderTestModel>> getAvailableOrderTests([int? shipperId]) async {
    try {
      final query =
          shipperId != null ? {'shipperId': shipperId.toString()} : null;
      final response =
          await ApiClient.get('api/OrderTests/available', queryParams: query);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        final apiOrders =
            list.map((json) => OrderTestModel.fromJson(json)).toList();
        if (apiOrders.isNotEmpty) {
          for (final ao in apiOrders) {
            final idx = _inMemoryOrders.indexWhere((o) => o.id == ao.id);
            if (idx == -1) {
              _inMemoryOrders.add(ao);
            } else {
              _inMemoryOrders[idx] = ao;
            }
          }
          _notifyChange();
          return apiOrders;
        }
      }
    } catch (e) {
      debugPrint('OrderTestService.getAvailableOrderTests error: $e');
    }

    // Trả về danh sách đơn trong bộ nhớ chia sẻ
    if (shipperId != null) {
      return _inMemoryOrders
          .where((o) =>
              o.status == 'Ready' ||
              (o.shipperId == shipperId && o.status != 'Completed'))
          .toList();
    }
    return _inMemoryOrders.where((o) => o.status == 'Ready').toList();
  }

  Future<bool> acceptOrderTest(int orderId, int shipperId) async {
    try {
      await ApiClient.put(
          'api/OrderTests/accept/$orderId?shipperId=$shipperId');
    } catch (e) {
      debugPrint('OrderTestService.acceptOrderTest API error: $e');
    }

    // Cập nhật trạng thái trong bộ nhớ
    final index = _inMemoryOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final old = _inMemoryOrders[index];
      _inMemoryOrders[index] = OrderTestModel(
        id: old.id,
        customerName: old.customerName,
        phone: old.phone,
        deliveryAddress: old.deliveryAddress,
        latitude: old.latitude,
        longitude: old.longitude,
        totalAmount: old.totalAmount,
        status: 'Delivering',
        shipperId: shipperId,
        createdAt: old.createdAt,
      );
      _notifyChange();
    }
    return true;
  }
}

