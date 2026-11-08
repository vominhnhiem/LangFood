import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langfood_flutter/core/network/api_client.dart';
import 'package:langfood_flutter/core/utils/display_format.dart';
import 'package:langfood_flutter/data/models/order_model.dart';
import 'package:langfood_flutter/data/models/user_model.dart';
import 'package:langfood_flutter/data/services/auth_service.dart';
import 'package:langfood_flutter/data/services/account_service.dart';
import 'package:langfood_flutter/data/services/order_service.dart';
import 'package:langfood_flutter/data/services/wallet_service.dart';
import 'package:langfood_flutter/features/account/presentation/screens/profile_screen.dart';
import 'package:langfood_flutter/features/orders/presentation/screens/my_orders_screen.dart';
import 'package:langfood_flutter/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';

class SessionApi extends AuthService {
  final UserModel profile;
  SessionApi(this.profile);
  @override
  Future<UserModel> login(String username, String password) async => profile;
  @override
  Future<UserModel> getUserById(String id) async => profile;
}

Future<AuthProvider> session({int role = 1}) async {
  final profile = UserModel(
    id: 'user',
    username: 'user',
    roleId: role,
    shipperId: role == 3 ? 7 : null,
    fullName: 'Test User',
    email: 'user@example.com',
    phoneNumber: '0987654321',
  );
  final auth = AuthProvider(
    service: SessionApi(profile),
    restoreSession: false,
  );
  await auth.login('user', 'password');
  return auth;
}

Widget host(AuthProvider auth, Widget page) => ChangeNotifierProvider.value(
  value: auth,
  child: MaterialApp(home: page),
);

class OrdersApi extends OrderService {
  final rows = [
    OrderModel(
      id: 1,
      buyerId: 'user',
      shopId: 1,
      status: 'PendingPayment',
      totalAmount: 10000,
      shippingFee: 10000,
    ),
    OrderModel(
      id: 2,
      buyerId: 'user',
      shopId: 1,
      status: 'Preparing',
      totalAmount: 20000,
      shippingFee: 10000,
    ),
    OrderModel(
      id: 3,
      buyerId: 'user',
      shopId: 1,
      status: 'Completed',
      totalAmount: 30000,
      shippingFee: 10000,
    ),
  ];
  int cancellations = 0;
  @override
  Future<List<OrderModel>> getBuyerOrders(String buyerId) async =>
      List.of(rows);
  @override
  Future<void> cancelOrder(int id) async {
    cancellations++;
    rows.removeWhere((o) => o.id == id);
  }
}

class BalanceApi extends WalletService {
  int deposits = 0;
  @override
  Future<WalletSnapshot> load(String userId) async =>
      WalletSnapshot(100000, [], []);
  @override
  Future<void> deposit(String userId, double amount) async {
    expect(amount, 25000);
    deposits++;
  }
}

class ProfileApi extends AccountService {
  @override
  Future<UserModel> update(
    UserModel current, {
    required String fullName,
    required String phone,
    int? buildingId,
    required String room,
  }) async => current.copyWith(
    fullName: fullName,
    phoneNumber: phone,
    buildingId: buildingId,
    ktxRoom: room,
    replaceBuilding: true,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => ApiClient.useClient(http.Client()));
  testWidgets(
    'history cancels only waiting orders after confirmation and removes them',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.65;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final auth = await session();
      addTearDown(auth.dispose);
      final api = OrdersApi();
      await tester.pumpWidget(host(auth, MyOrdersScreen(service: api)));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Hủy đơn'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();
      expect(api.cancellations, 0);
      await tester.tap(find.widgetWithText(FilledButton, 'Hủy đơn'));
      await tester.pumpAndSettle();
      expect(api.cancellations, 1);
      expect(find.text('Đơn #1'), findsNothing);
      expect(find.text('Hủy đơn'), findsNothing);
      await tester.tap(find.text('Đã kết thúc'));
      await tester.pumpAndSettle();
      expect(find.text('Đơn #3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('deposit request never optimistically increases wallet balance', (
    tester,
  ) async {
    final auth = await session(role: 3);
    addTearDown(auth.dispose);
    final api = BalanceApi();
    await tester.pumpWidget(host(auth, WalletScreen(service: api)));
    await tester.pumpAndSettle();
    expect(find.text(money(100000)), findsOneWidget);
    await tester.tap(find.text('Nạp tiền'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '25000');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(api.deposits, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await tester.pumpAndSettle();
    expect(api.deposits, 1);
    expect(find.text(money(100000)), findsOneWidget);
    expect(find.text(money(125000)), findsNothing);
  });
  testWidgets(
    'profile editing persists actual fields without losing shipper identity',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ApiClient.useClient(MockClient((_) async => http.Response('[]', 200)));
      final auth = await session(role: 3);
      addTearDown(auth.dispose);
      await tester.pumpWidget(host(auth, ProfileScreen(service: ProfileApi())));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Updated User');
      await tester.enterText(fields.at(1), '0909876543');
      await tester.enterText(fields.at(2), 'B405');
      final save = find.text('Lưu thay đổi');
      await tester.scrollUntilVisible(
        save,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(auth.user!.fullName, 'Updated User');
      expect(auth.user!.phoneNumber, '0909876543');
      expect(auth.user!.roleId, 3);
      expect(auth.user!.shipperId, 7);
      final prefs = await SharedPreferences.getInstance();
      final saved = jsonDecode(prefs.getString('USER_PROFILE')!);
      expect(saved['ktxRoom'], 'B405');
      expect(saved['shipperId'], 7);
    },
  );
}
