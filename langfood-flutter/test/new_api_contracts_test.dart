import 'package:langfood_flutter/data/models/cart_item_model.dart';
import 'package:langfood_flutter/data/services/cart_service.dart';

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langfood_flutter/core/network/api_client.dart';
import 'package:langfood_flutter/data/models/user_model.dart';
import 'package:langfood_flutter/data/models/product_model.dart';
import 'package:langfood_flutter/data/services/account_service.dart';
import 'package:langfood_flutter/data/services/order_service.dart';
import 'package:langfood_flutter/data/services/product_service.dart';
import 'package:langfood_flutter/data/services/wallet_service.dart';

http.Response reply(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  setUp(
    () => dotenv.loadFromString(envString: 'BASE_URL=https://example.com/api/'),
  );
  tearDown(() {
    ApiClient.useClient(http.Client());
    dotenv.clean();
  });
  test(
    'history uses current buyer and cancellation surfaces server status errors',
    () async {
      ApiClient.useClient(
        MockClient((request) async {
          if (request.method == 'GET') {
            expect(request.url.path, '/api/Orders/buyer/buyer');
            return reply([
              {
                'id': 4,
                'buyerId': 'buyer',
                'status': 'Preparing',
                'shippingFee': 12000,
              },
            ]);
          }
          expect(request.method, 'DELETE');
          expect(request.url.path, '/api/Orders/4');
          return reply({'message': 'Quán đã nhận đơn'}, 400);
        }),
      );
      final api = OrderService();
      final rows = await api.getBuyerOrders('buyer');
      expect(rows.single.canCancel, isFalse);
      expect(rows.single.shippingFee, 12000);
      await expectLater(
        api.cancelOrder(4),
        throwsA(predicate((e) => e.toString().contains('Quán đã nhận đơn'))),
      );
    },
  );
  test(
    'wallet loads actual balance and only submits pending deposit requests',
    () async {
      final requests = <http.Request>[];
      ApiClient.useClient(
        MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/Wallet/user/shipper')
            return reply({'balance': 175000});
          if (request.method == 'GET') return reply([]);
          expect(request.url.path, '/api/Wallet/deposit');
          expect(request.url.queryParameters['amount'], '25000.0');
          return reply({'message': 'Chờ duyệt'});
        }),
      );
      final api = WalletService();
      final data = await api.load('shipper');
      expect(data.balance, 175000);
      await api.deposit('shipper', 25000);
      expect(requests.any((r) => r.url.path.contains('approve')), isFalse);
      expect(data.balance, 175000);
    },
  );
  test(
    'withdrawal sends existing DTO and rejects invalid amounts before request',
    () async {
      var calls = 0;
      ApiClient.useClient(
        MockClient((request) async {
          calls++;
          expect(request.url.path, '/api/Wallet/withdrawal-request');
          final body = jsonDecode(request.body);
          expect(body['userId'], 'shipper');
          expect(body['bankAccountNumber'], '012345');
          expect(body['bankAccountName'], 'Test User');
          return reply({'message': 'Chờ duyệt'});
        }),
      );
      final api = WalletService();
      await expectLater(
        api.withdraw(
          'shipper',
          amount: 10000,
          bank: 'Bank',
          account: '012345',
          owner: 'Test User',
        ),
        throwsException,
      );
      expect(calls, 0);
      await api.withdraw(
        'shipper',
        amount: 50000,
        bank: 'Bank',
        account: '012345',
        owner: 'Test User',
      );
      expect(calls, 1);
    },
  );
  test(
    'profile updates keep shipper identity and use multipart image field',
    () async {
      ApiClient.useClient(
        MockClient((request) async {
          if (request.url.path.endsWith('upload-avatar/shipper')) {
            expect(
              request.headers['content-type'],
              contains('multipart/form-data'),
            );
            expect(request.body, contains('name="image"'));
            expect(request.body, contains('filename="avatar.jpg"'));
            return reply({'url': '/images/avatars/user.jpg'});
          }
          if (request.method == 'PUT') {
            final body = jsonDecode(request.body);
            expect(body['fullName'], 'Updated');
            expect(body['phoneNumber'], '0987654321');
            expect(body.containsKey('roleId'), isFalse);
            return reply({'id': 'shipper'});
          }
          return reply({
            'id': 'shipper',
            'username': 'driver',
            'roleId': 3,
            'fullName': 'Updated',
            'shipper': {'id': 9},
          });
        }),
      );
      final user = UserModel(
        id: 'shipper',
        username: 'driver',
        roleId: 3,
        shipperId: 9,
      );
      final api = AccountService();
      final saved = await api.update(
        user,
        fullName: 'Updated',
        phone: '0987654321',
        buildingId: null,
        room: 'B402',
      );
      expect(saved.shipperId, 9);
      expect(saved.roleId, 3);
      expect(
        await api.uploadAvatar('shipper', [1, 2, 3], 'avatar.jpg'),
        '/images/avatars/user.jpg',
      );
    },
  );
  test(
    'merchant create/upload/edit/delete match available backend contracts',
    () async {
      final methods = <String>[];
      ApiClient.useClient(
        MockClient((request) async {
          methods.add('${request.method} ${request.url.path}');
          if (request.url.path.endsWith('/upload')) {
            expect(
              request.headers['content-type'],
              contains('multipart/form-data'),
            );
            expect(request.body, contains('name="shopId"'));
            expect(request.body, contains('name="categoryId"'));
            return reply({'id': 8, 'status': 0});
          }
          if (request.method != 'DELETE') {
            final body = jsonDecode(request.body);
            expect(body['shopId'], 2);
            expect(body['categoryId'], 3);
            expect(body['price'], 35000);
          }
          return reply({'message': 'OK'});
        }),
      );
      final api = ProductService();
      await api.saveProduct(
        shopId: 2,
        categoryId: 3,
        name: 'Món mới',
        price: 35000,
        description: 'Mô tả',
        imageUrl: 'https://example.com/food.jpg',
      );
      await api.saveProduct(
        shopId: 2,
        categoryId: 3,
        name: 'Món ảnh',
        price: 35000,
        description: 'Mô tả',
        imageBytes: [1, 2, 3],
        imageName: 'food.jpg',
      );
      await api.saveProduct(
        existing: ProductModel(
          id: 8,
          shopId: 2,
          shopName: 'Quán',
          name: 'Món',
          price: 30000,
        ),
        shopId: 2,
        categoryId: 3,
        name: 'Món sửa',
        price: 35000,
        description: 'Mô tả',
        imageUrl: 'https://example.com/new.jpg',
      );
      await api.deleteProduct(8);
      expect(methods, [
        'POST /api/Products',
        'POST /api/Products/upload',
        'PUT /api/Products/8',
        'DELETE /api/Products/8',
      ]);
    },
  );

  test(
    'cart snapshot round-trip keeps variants, quantities and selected prices',
    () async {
      final rows = <Map<String, dynamic>>[];
      final product = ProductModel(
        id: 1,
        name: 'Món',
        price: 10000,
        shopId: 2,
        shopName: 'Quán',
      );
      ApiClient.useClient(
        MockClient((request) async {
          if (request.method == 'DELETE') {
            rows.clear();
            return reply({});
          }
          if (request.method == 'POST') {
            final values = request.url.queryParameters;
            expect(request.url.path, '/api/Cart');
            rows.add({
              'product': product.toJson(),
              'quantity': int.parse(values['quantity']!),
              'note': values['note'],
              'selectedOptions': values['selectedOptions'],
            });
            return reply({});
          }
          return reply(rows);
        }),
      );
      final api = CartService();
      await api.replaceCart('buyer', [
        CartItemModel(
          product: product,
          quantity: 2,
          selectedOptionsJson: 'Trứng',
          unitPrice: 15000,
        ),
        CartItemModel(
          product: product,
          quantity: 1,
          note: 'Không cay',
          unitPrice: 10000,
        ),
      ]);
      final restored = await api.getCart('buyer');
      expect(restored, hasLength(2));
      expect(restored.first.totalPrice, 30000);
      expect(restored.first.selectedOptionsSummary, 'Trứng');
      expect(restored.last.note, 'Không cay');
      expect(restored.last.totalPrice, 10000);
    },
  );
}
