import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langfood_flutter/core/network/api_client.dart';
import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/data/models/order_model.dart';
import 'package:langfood_flutter/data/models/order_test_model.dart';
import 'package:langfood_flutter/data/services/order_service.dart';
import 'package:langfood_flutter/features/tracking/presentation/screens/live_tracking_screen.dart';
import 'package:langfood_flutter/features/shipper/presentation/screens/shipper_orders_screen.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'new_screens_test.dart' show session;
import 'ui_06_checkout_and_location_test.dart' show TestTileProvider;

class MockShipperApi extends OrderService {
  OrderModel currentOrder;
  Map<String, dynamic> shopPickup;
  Map<String, dynamic>? shipperLoc;

  int confirmPickupCalls = 0;
  int completeOrderCalls = 0;
  double? lastLat;
  double? lastLng;

  MockShipperApi({
    required this.currentOrder,
    required this.shopPickup,
    this.shipperLoc,
  });

  @override
  Future<OrderModel?> getOrderById(int id) async => currentOrder;

  @override
  Future<Map<String, dynamic>> getShopPickup(int shopId) async => shopPickup;

  @override
  Future<Map<String, dynamic>?> getShipperLocation(int orderId) async =>
      shipperLoc;

  @override
  Future<bool> confirmPickup(
    int orderId,
    int shipperId, {
    double? lat,
    double? lng,
  }) async {
    confirmPickupCalls++;
    lastLat = lat;
    lastLng = lng;
    return true;
  }

  @override
  Future<bool> completeOrder(int orderId, {double? lat, double? lng}) async {
    completeOrderCalls++;
    lastLat = lat;
    lastLng = lng;
    return true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'SHIPPING_FEE=10000');
  });

  Widget host(AuthProvider auth, Widget page) => ChangeNotifierProvider.value(
    value: auth,
    child: MaterialApp(theme: AppTheme.lightTheme, home: page),
  );

  testWidgets(
    'rapid taps send one claim and a rejected claim stays on the list',
    (tester) async {
      final auth = await session(role: 3);
      final response = Completer<http.Response>();
      var claims = 0;
      ApiClient.useClient(
        MockClient((request) {
          expect(request.method, 'PUT');
          expect(request.url.path, endsWith('/Orders/201/claim'));
          claims++;
          return response.future;
        }),
      );
      addTearDown(() => ApiClient.useClient(http.Client()));
      await tester.pumpWidget(
        host(
          auth,
          ShipperOrdersScreen(
            enablePeriodicTimer: false,
            initialOrders: [
              OrderTestModel(
                id: 201,
                customerName: 'Sinh viên kiểm thử',
                deliveryAddress: 'Tòa BA2 · Sảnh G',
                phone: '',
                latitude: 0,
                longitude: 0,
                totalAmount: 32000,
              ),
            ],
          ),
        ),
      );
      final claim = find.text('NHẬN ĐƠN NGAY');
      await tester.ensureVisible(claim);
      await tester.tap(claim);
      await tester.tap(claim);
      await tester.pump();
      expect(claims, 1);

      response.complete(
        http.Response(
          '{"message":"Đơn đã được nhận"}',
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Không thể nhận đơn'), findsOneWidget);
      expect(find.byType(LiveTrackingScreen), findsNothing);
      expect(claim.hitTestable(), findsOneWidget);
    },
  );

  group('Shipper Geofence Confirmation Tests', () {
    testWidgets(
      'PickingUp: Shipper is far (> 200m) -> Shows warning and blocks confirmPickup',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = await session(role: 3);

        // Quán ở (10.8845, 106.7842)
        // Shipper ở (10.8900, 106.7900) -> Khoảng cách ~870m (> 200m)
        final api = MockShipperApi(
          currentOrder: OrderModel(
            id: 201,
            buyerId: 'customer_01',
            shopId: 1,
            shipperId: 7,
            status: 'PickingUp',
            totalAmount: 45000,
            shippingFee: 10000,
            deliveryLatitude: 10.8800,
            deliveryLongitude: 106.7800,
          ),
          shopPickup: {
            'address': 'Quán Cơm Tân Lập - KTX B',
            'latitude': 10.8845,
            'longitude': 106.7842,
          },
          shipperLoc: {
            'latitude': 10.8900,
            'longitude': 106.7900,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        await tester.pumpWidget(
          host(
            auth,
            LiveTrackingScreen(
              orderId: 201,
              isShipper: true,
              service: api,
              tileProvider: TestTileProvider(),
              enablePeriodicTimer: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kiểm tra Geofence card cảnh báo chưa vào phạm vi
        expect(find.textContaining('Chưa vào phạm vi'), findsOneWidget);
        expect(find.textContaining('Lại gần quán để xác nhận'), findsOneWidget);

        // 2. Bấm nút khi đang ở xa
        await tester.tap(find.textContaining('Lại gần quán để xác nhận'));
        await tester.pumpAndSettle();

        // 3. Hiển thị Dialog cảnh báo "Chưa đến gần quán"
        expect(find.text('Chưa đến gần quán'), findsOneWidget);
        expect(find.text('Đã hiểu'), findsOneWidget);

        // Đóng dialog
        await tester.tap(find.text('Đã hiểu'));
        await tester.pumpAndSettle();

        // 4. API confirmPickup tuyệt đối KHÔNG được gọi
        expect(api.confirmPickupCalls, 0);
      },
    );

    testWidgets(
      'PickingUp: Shipper is near (<= 200m) -> Green badge and confirms pickup',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = await session(role: 3);

        // Quán ở (10.8845, 106.7842)
        // Shipper ở (10.8846, 106.7843) -> Khoảng cách ~15m (< 200m)
        final api = MockShipperApi(
          currentOrder: OrderModel(
            id: 202,
            buyerId: 'customer_01',
            shopId: 1,
            shipperId: 7,
            status: 'PickingUp',
            totalAmount: 45000,
            shippingFee: 10000,
            deliveryLatitude: 10.8800,
            deliveryLongitude: 106.7800,
          ),
          shopPickup: {
            'address': 'Quán Cơm Tân Lập - KTX B',
            'latitude': 10.8845,
            'longitude': 106.7842,
          },
          shipperLoc: {
            'latitude': 10.8846,
            'longitude': 106.7843,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        await tester.pumpWidget(
          host(
            auth,
            LiveTrackingScreen(
              orderId: 202,
              isShipper: true,
              service: api,
              tileProvider: TestTileProvider(),
              enablePeriodicTimer: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kiểm tra Geofence card xanh lá "Đã vào phạm vi"
        expect(find.textContaining('Đã vào phạm vi'), findsOneWidget);
        expect(find.text('Đã lấy món tại quán'), findsOneWidget);

        // 2. Bấm xác nhận đã lấy món
        await tester.tap(find.text('Đã lấy món tại quán'));
        await tester.pumpAndSettle();

        // 3. API confirmPickup được gọi với tọa độ shipper
        expect(api.confirmPickupCalls, 1);
        expect(api.lastLat, closeTo(10.8846, 0.001));
        expect(api.lastLng, closeTo(106.7843, 0.001));
      },
    );

    testWidgets(
      'Delivering: Shipper is far (> 200m) -> Shows warning and blocks completeOrder',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = await session(role: 3);

        // Điểm giao KTX ở (10.8800, 106.7800)
        // Shipper ở (10.8900, 106.7900) -> Khoảng cách ~1.5km (> 200m)
        final api = MockShipperApi(
          currentOrder: OrderModel(
            id: 203,
            buyerId: 'customer_01',
            shopId: 1,
            shipperId: 7,
            status: 'Delivering',
            totalAmount: 45000,
            shippingFee: 10000,
            deliveryBuilding: 'Tòa BA2 KTX B',
            deliveryLatitude: 10.8800,
            deliveryLongitude: 106.7800,
          ),
          shopPickup: {
            'address': 'Quán Cơm Tân Lập - KTX B',
            'latitude': 10.8845,
            'longitude': 106.7842,
          },
          shipperLoc: {
            'latitude': 10.8900,
            'longitude': 106.7900,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        await tester.pumpWidget(
          host(
            auth,
            LiveTrackingScreen(
              orderId: 203,
              isShipper: true,
              service: api,
              tileProvider: TestTileProvider(),
              enablePeriodicTimer: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kiểm tra Geofence card cảnh báo chưa vào phạm vi
        expect(find.textContaining('Chưa vào phạm vi'), findsOneWidget);
        expect(
          find.textContaining('Lại gần điểm giao để xác nhận'),
          findsOneWidget,
        );

        // 2. Bấm nút khi đang ở xa
        await tester.tap(find.textContaining('Lại gần điểm giao để xác nhận'));
        await tester.pumpAndSettle();

        // 3. Hiển thị Dialog cảnh báo "Chưa đến điểm giao"
        expect(find.text('Chưa đến điểm giao'), findsOneWidget);
        expect(find.text('Đã hiểu'), findsOneWidget);

        await tester.tap(find.text('Đã hiểu'));
        await tester.pumpAndSettle();

        // 4. API completeOrder tuyệt đối KHÔNG được gọi
        expect(api.completeOrderCalls, 0);
      },
    );

    testWidgets(
      'Delivering: Shipper is near (<= 200m) -> Green badge and completes order',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final auth = await session(role: 3);

        // Điểm giao KTX ở (10.8800, 106.7800)
        // Shipper ở (10.8801, 106.7801) -> Khoảng cách ~15m (< 200m)
        final api = MockShipperApi(
          currentOrder: OrderModel(
            id: 204,
            buyerId: 'customer_01',
            shopId: 1,
            shipperId: 7,
            status: 'Delivering',
            totalAmount: 45000,
            shippingFee: 10000,
            deliveryBuilding: 'Tòa BA2 KTX B',
            deliveryLatitude: 10.8800,
            deliveryLongitude: 106.7800,
          ),
          shopPickup: {
            'address': 'Quán Cơm Tân Lập - KTX B',
            'latitude': 10.8845,
            'longitude': 106.7842,
          },
          shipperLoc: {
            'latitude': 10.8801,
            'longitude': 106.7801,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        await tester.pumpWidget(
          host(
            auth,
            LiveTrackingScreen(
              orderId: 204,
              isShipper: true,
              service: api,
              tileProvider: TestTileProvider(),
              enablePeriodicTimer: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kiểm tra Geofence card xanh lá "Đã vào phạm vi"
        expect(find.textContaining('Đã vào phạm vi'), findsOneWidget);
        expect(find.text('Đã giao xong'), findsOneWidget);

        // 2. Bấm "Đã giao xong"
        await tester.tap(find.text('Đã giao xong'));
        await tester.pumpAndSettle();

        // 3. Hiển thị dialog xác nhận giao hàng
        expect(find.text('Xác nhận đã giao món?'), findsOneWidget);

        // Bấm xác nhận trong dialog
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        // 4. API completeOrder được gọi thành công kèm tọa độ
        expect(api.completeOrderCalls, 1);
        expect(api.lastLat, closeTo(10.8801, 0.001));
        expect(api.lastLng, closeTo(106.7801, 0.001));
      },
    );
  });
}
