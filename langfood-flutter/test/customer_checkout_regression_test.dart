import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langfood_flutter/core/network/api_client.dart';
import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/core/utils/display_format.dart';
import 'package:langfood_flutter/data/models/cart_item_model.dart';
import 'package:langfood_flutter/data/models/checkout_selection.dart';
import 'package:langfood_flutter/data/models/order_model.dart';
import 'package:langfood_flutter/data/models/product_model.dart';
import 'package:langfood_flutter/data/services/cart_service.dart';
import 'package:langfood_flutter/data/services/order_service.dart';
import 'package:langfood_flutter/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:langfood_flutter/features/tracking/presentation/screens/live_tracking_screen.dart';
import 'package:langfood_flutter/features/tracking/presentation/screens/location_picker_screen.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:langfood_flutter/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

import 'new_screens_test.dart' show session;
import 'ui_06_checkout_and_location_test.dart' show TestTileProvider;

class LocalCart extends CartService {
  @override
  Future<List<CartItemModel>> getCart(String userId) async => [];
  @override
  Future<void> replaceCart(String userId, List<CartItemModel> items) async {}
}

class CheckoutApi extends OrderService {
  final List<OrderModel> requests = [];
  bool failSecond = false;
  bool uncertain = false;
  Completer<void>? gate;
  @override
  Future<OrderModel?> createOrder(OrderModel order) async {
    requests.add(order);
    if (gate != null) await gate!.future;
    if (uncertain) throw const OrderSubmissionUncertain('Mất kết nối');
    if (failSecond && order.shopId == 2) throw Exception('Quán tạm đóng cửa');
    return OrderModel.fromJson({...order.toJson(), 'id': order.shopId + 100});
  }

  @override
  Future<OrderModel?> getOrderById(int id) async => OrderModel(
    id: id,
    buyerId: 'user',
    shopId: 1,
    totalAmount: 35000,
    status: 'Pending',
  );
  int locationReads = 0;
  @override
  Future<Map<String, dynamic>?> getShipperLocation(int orderId) async {
    locationReads++;
    return null;
  }
}

ProductModel product(int id, int shop) => ProductModel(
  id: id,
  name: 'Món $id',
  description: '',
  price: 35000,
  shopId: shop,
  shopName: 'Quán $shop',
);
const location = CampusDeliveryLocation(
  position: LatLng(10.88, 106.805),
  buildingName: 'KTX B',
  subAddress: '',
  dropOffOptionKey: 'g',
  dropOffOptionLabel: 'Sảnh G',
  shipperNote: 'Gọi khi tới sảnh',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'SHIPPING_FEE=10000');
  });

  Future<(AuthProvider, CartProvider)> prepare() async {
    final auth = await session();
    final cart = CartProvider(service: LocalCart());
    await cart.loadCartFromServer('user');
    return (auth, cart);
  }

  Widget host(AuthProvider auth, CartProvider cart, Widget page) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: cart),
        ],
        child: MaterialApp(theme: AppTheme.lightTheme, home: page),
      );

  testWidgets(
    'door delivery requires room and returns without another checkout',
    (tester) async {
      final (auth, cart) = await prepare();
      CampusDeliveryLocation? result;
      await tester.pumpWidget(
        host(
          auth,
          cart,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<CampusDeliveryLocation>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerScreen(
                        initialLocation: location.copyWith(
                          dropOffOptionKey: 'door',
                          extraFee: 5000,
                        ),
                        returnResult: true,
                        tileProvider: TestTileProvider(),
                      ),
                    ),
                  );
                },
                child: const Text('Chọn điểm nhận'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Chọn điểm nhận'));
      await tester.pumpAndSettle();
      final confirm = find.text('Xác nhận điểm giao này');
      await tester.drag(
        find.text('Chi tiết điểm nhận món'),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        confirm,
        200,
        scrollable: find
            .descendant(
              of: find.byType(DraggableScrollableSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(LocationPickerScreen), findsOneWidget);
      final room = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Số phòng nhận món',
      );
      await tester.ensureVisible(room);
      await tester.enterText(room, '512');
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result?.room, '512');
      expect(result?.dropOffOptionLabel, contains('512'));
      expect(find.byType(CheckoutScreen), findsNothing);
      expect(find.byType(LocationPickerScreen), findsNothing);
    },
  );

  testWidgets('empty checkout has no submit button or invented subtotal', (
    tester,
  ) async {
    final (auth, cart) = await prepare();
    final api = CheckoutApi();
    await tester.pumpWidget(
      host(
        auth,
        cart,
        CheckoutScreen(deliveryLocation: location, service: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đặt đơn ngay'), findsNothing);
    expect(find.text(money(48000)), findsNothing);
    expect(api.requests, isEmpty);
  });

  testWidgets(
    'selected snapshot creates only selected lines and preserves other cart items',
    (tester) async {
      final (auth, cart) = await prepare();
      cart.addToCart(product: product(1, 1), quantity: 2, note: 'Ít cay');
      cart.addToCart(product: product(2, 2));
      final selected = CheckoutSelection(
        [cart.items.first],
        shopNotes: {1: 'Để riêng nước sốt'},
      );
      final api = CheckoutApi();
      await tester.pumpWidget(
        host(
          auth,
          cart,
          CheckoutScreen(
            deliveryLocation: location,
            selection: selected,
            service: api,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt đơn ngay'));
      await tester.pumpAndSettle();
      expect(api.requests, hasLength(1));
      final request = api.requests.single;
      expect(request.shopId, 1);
      expect(request.orderItems.single.productId, 1);
      expect(request.orderItems.single.quantity, 2);
      expect(request.orderItems.single.note, contains('Để riêng nước sốt'));
      expect(request.deliveryRoom, contains('Gọi khi tới sảnh'));
      expect(request.totalAmount, 70000);
      expect(request.shippingFee, 10000);
      expect(cart.items.single.product.id, 2);
      expect(find.text('Đặt đơn thành công!'), findsOneWidget);
      expect(find.text(money(48000)), findsNothing);
    },
  );

  testWidgets('partial multi-shop failure retries only the uncreated shop', (
    tester,
  ) async {
    final (auth, cart) = await prepare();
    cart.addToCart(product: product(1, 1));
    cart.addToCart(product: product(2, 2));
    final api = CheckoutApi()..failSecond = true;
    await tester.pumpWidget(
      host(
        auth,
        cart,
        CheckoutScreen(deliveryLocation: location, service: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt đơn ngay'));
    await tester.pumpAndSettle();
    expect(api.requests.map((order) => order.shopId).toList(), [1, 2]);
    expect(cart.items.single.product.shopId, 2);
    api.failSecond = false;
    await tester.tap(find.text('Đặt các đơn còn lại'));
    await tester.pumpAndSettle();
    expect(api.requests.map((order) => order.shopId).toList(), [1, 2, 2]);
    expect(
      api.requests.last.orderItems.every((item) => item.productId == 2),
      isTrue,
    );
    expect(cart.items, isEmpty);
  });

  testWidgets('double tap sends once while a request is pending', (
    tester,
  ) async {
    final (auth, cart) = await prepare();
    cart.addToCart(product: product(1, 1));
    final api = CheckoutApi()..gate = Completer<void>();
    await tester.pumpWidget(
      host(
        auth,
        cart,
        CheckoutScreen(deliveryLocation: location, service: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt đơn ngay'));
    await tester.tap(find.text('Đặt đơn ngay'));
    await tester.pump();
    expect(api.requests, hasLength(1));
    api.gate!.complete();
    await tester.pumpAndSettle();
    expect(api.requests, hasLength(1));
  });

  testWidgets(
    'uncertain network outcome keeps cart and prevents immediate duplicate submission',
    (tester) async {
      final (auth, cart) = await prepare();
      cart.addToCart(product: product(1, 1));
      final api = CheckoutApi()..uncertain = true;
      await tester.pumpWidget(
        host(
          auth,
          cart,
          CheckoutScreen(deliveryLocation: location, service: api),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt đơn ngay'));
      await tester.pumpAndSettle();
      expect(cart.items, hasLength(1));
      expect(api.requests, hasLength(1));
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Đặt đơn ngay'),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Đặt đơn thành công!'), findsNothing);
    },
  );

  testWidgets('pending tracking never invents a driver or queries GPS', (
    tester,
  ) async {
    final (auth, cart) = await prepare();
    final api = CheckoutApi();
    await tester.pumpWidget(
      host(
        auth,
        cart,
        LiveTrackingScreen(
          orderId: 107,
          service: api,
          tileProvider: TestTileProvider(),
          enablePeriodicTimer: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chờ quán xác nhận'), findsOneWidget);
    expect(find.text('Tài xế đang giao'), findsNothing);
    expect(find.byIcon(Icons.delivery_dining), findsNothing);
    expect(api.locationReads, 0);
  });

  test('restored cart resolves missing shop name and keeps selected price and notes', () async {
    ApiClient.useClient(
      MockClient((request) async {
        final Object data = request.url.path == '/api/Cart/user'
            ? [
                {
                  'product': {
                    'id': 1,
                    'name': 'Món 1',
                    'price': 35000,
                    'shopId': 1,
                  },
                  'quantity': 2,
                  'note': 'Ít cay',
                  'selectedOptions': jsonEncode({
                    'summary': 'Thêm trứng',
                    'unitPrice': 40000,
                  }),
                },
              ]
            : {'id': 1, 'name': 'Quán thật', 'address': 'KTX B'};
        return http.Response(
          jsonEncode(data),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final cart = await CartService().getCart('user');
    expect(cart.single.product.shopName, 'Quán thật');
    expect(cart.single.effectiveUnitPrice, 40000);
    expect(cart.single.selectedOptionsSummary, 'Thêm trứng');
    expect(cart.single.note, 'Ít cay');
    expect(cart.single.quantity, 2);
  });

  test('selection remains stable after cart quantity changes', () {
    final item = CartItemModel(product: product(1, 1), quantity: 2);
    final selected = CheckoutSelection([item]);
    item.quantity = 9;
    expect(selected.items.single.quantity, 2);
    expect(selected.subtotal, 70000);
  });

  test('missing Orders response never falls back to OrderTests', () async {
    final paths = <String>[];
    ApiClient.useClient(
      MockClient((request) async {
        paths.add(request.url.path);
        return http.Response('', 404);
      }),
    );
    expect(await OrderService().getOrderById(123), isNull);
    expect(paths, ['/api/Orders/123']);
  });

  test(
    'rejected Orders submission is reported with no second API write',
    () async {
      final paths = <String>[];
      ApiClient.useClient(
        MockClient((request) async {
          paths.add(request.url.path);
          return http.Response(jsonEncode({'message': 'Quán đã đóng'}), 400);
        }),
      );
      await expectLater(
        OrderService().createOrder(
          OrderModel(
            buyerId: 'user',
            shopId: 1,
            totalAmount: 35000,
            orderItems: [
              OrderItemModel(productId: 1, quantity: 1, unitPrice: 35000),
            ],
          ),
        ),
        throwsException,
      );
      expect(paths, ['/api/Orders']);
    },
  );
}
