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

  /// Tạo đơn test.
  ///
  /// Hành vi:
  /// - Luôn thêm đơn vào [_inMemoryOrders] ngay (optimistic update) để
  ///   [ShipperOrdersScreen] hiển thị tức thì qua [ordersNotifier].
  /// - Nếu server phản hồi 200/201: cập nhật đơn với dữ liệu từ server và trả về.
  /// - Nếu server lỗi hoặc mạng lỗi: đơn giả lập vẫn GIỮ NGUYÊN trong in-memory
  ///   (shipper vẫn thấy), nhưng ném [Exception] để [CheckoutScreen] biết không
  ///   xóa giỏ hàng và hiện thông báo lỗi cho người dùng.
  Future<OrderTestModel?> createOrderTest(OrderTestModel order) async {
    // Thêm đơn giả lập vào in-memory ngay (optimistic update cho shipper screen)
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
      // Đọc body và trim để tránh FormatException khi body rỗng
      final body = utf8.decode(response.bodyBytes).trim();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse JSON nếu body không rỗng, cập nhật đơn giả lập với dữ liệu thực
        if (body.isNotEmpty) {
          try {
            final data = jsonDecode(body);
            final created = OrderTestModel.fromJson(data);
            _inMemoryOrders[0] = created;
            _notifyChange();
            return created;
          } catch (_) {
            // Body không phải JSON hợp lệ → trả đơn giả lập (thành công về UX)
          }
        }
        // Body rỗng nhưng status 200/201 → thành công, trả đơn giả lập
        return simulated;
      } else {
        // Lỗi server (4xx/5xx):
        // - Đơn giả lập VẪN GIỮ trong in-memory (shipper vẫn thấy)
        // - Throw để checkout_screen biết thất bại → giữ giỏ hàng + hiện lỗi
        String errMessage =
            'Không thể tạo đơn test (${response.statusCode})';
        if (body.isNotEmpty) {
          try {
            final err = jsonDecode(body);
            errMessage =
                (err is Map ? err['message'] as String? : null) ?? errMessage;
          } catch (_) {
            if (body.length < 200) errMessage = body;
          }
        }
        debugPrint('OrderTestService.createOrderTest server error: $errMessage');
        throw Exception(errMessage);
      }
    } catch (e) {
      // Lỗi mạng (timeout, offline, 400 từ test framework):
      // - Đơn giả lập VẪN GIỮ trong in-memory (shipper vẫn thấy, optimistic UX)
      // - Rethrow để checkout_screen giữ giỏ hàng + hiện lỗi
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
        final body = utf8.decode(response.bodyBytes).trim();
        if (body.isNotEmpty) {
          final List list = jsonDecode(body);
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
