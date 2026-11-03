import 'package:flutter_test/flutter_test.dart';
import 'package:langfood_flutter/data/models/order_model.dart';
import 'package:langfood_flutter/data/models/product_option_model.dart';

void main() {
  test(
    'server payment state is preserved and missing fees are not invented',
    () {
      final order = OrderModel.fromJson({'id': 12, 'status': 'PendingPayment'});
      expect(order.statusLabel, 'Chờ thanh toán');
      expect(order.shippingFee, isNull);
      expect(order.toJson().containsKey('shippingFee'), isFalse);
      expect(OrderModel.fromJson({}).statusLabel, 'Chưa xác định trạng thái');
    },
  );
  test('reads option surcharge and filters unavailable database options', () {
    final group = ProductOptionGroupModel.fromJson({
      'id': 1,
      'name': 'Topping',
      'maxSelectable': 2,
      'options': [
        {
          'id': 2,
          'name': 'Trứng',
          'additionalPrice': 5000,
          'isAvailable': true,
        },
        {
          'id': 3,
          'name': 'Hết hàng',
          'additionalPrice': 9000,
          'isAvailable': false,
        },
      ],
    });
    expect(group.isMultiple, isTrue);
    expect(group.options.length, 1);
    expect(group.options.single.price, 5000);
  });

  test(
    'order serialization never substitutes demo buyer, shop or subtotal',
    () {
      final json = OrderModel(buyerId: '', shopId: 0, totalAmount: 0).toJson();
      expect(json['buyerId'], '');
      expect(json['shopId'], 0);
      expect(json['totalAmount'], 0);
      expect(json['deliveryPhone'], isNull);
      expect(json['deliveryBuilding'], isNull);
    },
  );

  test('selected delivery coordinates survive order serialization', () {
    final json = OrderModel(
      buyerId: 'buyer',
      shopId: 2,
      totalAmount: 20000,
      deliveryLatitude: 10.88,
      deliveryLongitude: 106.8,
    ).toJson();
    expect(json['deliveryLatitude'], 10.88);
    expect(json['deliveryLongitude'], 106.8);
  });
}
