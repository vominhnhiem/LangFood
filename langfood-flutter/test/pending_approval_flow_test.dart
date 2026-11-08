import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langfood_flutter/core/network/api_client.dart';
import 'package:langfood_flutter/data/models/user_model.dart';
import 'package:langfood_flutter/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:langfood_flutter/features/home/presentation/screens/home_screen.dart';
import 'package:langfood_flutter/features/restaurant/presentation/screens/shop_orders_screen.dart';
import 'package:langfood_flutter/features/shipper/presentation/screens/shipper_orders_screen.dart';
import 'package:langfood_flutter/main.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:langfood_flutter/providers/cart_provider.dart';
import 'package:provider/provider.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _mockUser;
  bool _mockIsLoggedIn = false;

  void setMockUser(UserModel? user) {
    _mockUser = user;
    _mockIsLoggedIn = user != null;
    notifyListeners();
  }

  @override
  UserModel? get user => _mockUser;

  @override
  bool get isLoggedIn => _mockIsLoggedIn;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  String? get accessToken => 'mock_token';

  @override
  Future<UserModel?> refreshProfile() async {
    return _mockUser;
  }

  @override
  Future<void> logout() async {
    _mockUser = null;
    _mockIsLoggedIn = false;
    notifyListeners();
  }

  @override
  Future<bool> login(String username, String password) async => true;

  @override
  Future<void> loadUserFromPrefs() async {}

  @override
  Future<void> setProfile(UserModel profile) async {
    _mockUser = profile;
    notifyListeners();
  }
}

void main() {
  group('Pending Approval Flow & Screen Tests', () {
    testWidgets(
      'PendingApprovalScreen displays seller pending status correctly',
      (WidgetTester tester) async {
        final mockAuth = MockAuthProvider();
        mockAuth.setMockUser(
          UserModel(
            id: 'seller_1',
            username: 'seller_banhmì',
            fullName: 'Nguyễn Văn Bán Mì',
            phoneNumber: '0987654321',
            roleId: 2,
            isApproved: false,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: mockAuth,
              child: const PendingApprovalScreen(),
            ),
          ),
        );

        expect(find.text('Hồ sơ đang chờ phê duyệt'), findsOneWidget);
        expect(find.text('Đối tác Chủ quán (Seller)'), findsOneWidget);
        expect(find.text('Nguyễn Văn Bán Mì'), findsOneWidget);
        expect(find.text('seller_banhmì'), findsOneWidget);
        expect(find.text('0987654321'), findsOneWidget);
        expect(find.text('Đang chờ Admin duyệt'), findsOneWidget);
        expect(find.text('KIỂM TRA TRẠNG THÁI'), findsOneWidget);
        expect(find.text('ĐĂNG XUẤT'), findsOneWidget);
      },
    );

    testWidgets(
      'PendingApprovalScreen displays shipper pending status correctly',
      (WidgetTester tester) async {
        final mockAuth = MockAuthProvider();
        mockAuth.setMockUser(
          UserModel(
            id: 'shipper_1',
            username: 'shipper_hung',
            fullName: 'Trần Văn Hùng',
            phoneNumber: '0912345678',
            roleId: 3,
            isApproved: false,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<AuthProvider>.value(
              value: mockAuth,
              child: const PendingApprovalScreen(),
            ),
          ),
        );

        expect(find.text('Hồ sơ đang chờ phê duyệt'), findsOneWidget);
        expect(find.text('Đối tác Tài xế (Shipper)'), findsOneWidget);
        expect(find.text('Trần Văn Hùng'), findsOneWidget);
        expect(find.text('KIỂM TRA TRẠNG THÁI'), findsOneWidget);
      },
    );

    testWidgets(
      'AuthWrapper routes unapproved Seller to PendingApprovalScreen',
      (WidgetTester tester) async {
        final mockAuth = MockAuthProvider();
        mockAuth.setMockUser(
          UserModel(
            id: 'seller_2',
            username: 'shop_tra_sua',
            roleId: 2,
            isApproved: false,
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
              ChangeNotifierProvider<CartProvider>(
                create: (_) => CartProvider(),
              ),
            ],
            child: const MaterialApp(home: AuthWrapper()),
          ),
        );

        expect(find.byType(PendingApprovalScreen), findsOneWidget);
        expect(find.byType(ShopOrdersScreen), findsNothing);
      },
    );

    testWidgets('approved seller sees real API orders and can advance them', (
      WidgetTester tester,
    ) async {
      var status = 'Pending';
      final actions = <String>[];
      ApiClient.useClient(
        MockClient((request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/Orders/shop/10')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 127,
                  'status': status,
                  'shopId': 10,
                  'buyerName': 'Khách KTX',
                  'deliveryBuilding': 'Tòa BA2',
                  'deliveryRoom': 'Sảnh tầng G',
                  'orderItems': [
                    {'productId': 4, 'productName': 'Cơm gà', 'quantity': 1},
                  ],
                },
              ]),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          if (request.method == 'PUT') {
            actions.add(
              request.url.pathSegments[request.url.pathSegments.length - 2],
            );
            status = actions.length == 1 ? 'Preparing' : 'Ready';
            return http.Response('', 200);
          }
          return http.Response('', 404);
        }),
      );
      addTearDown(() => ApiClient.useClient(http.Client()));
      final mockAuth = MockAuthProvider();
      mockAuth.setMockUser(
        UserModel(
          id: 'seller_3',
          username: 'shop_active',
          roleId: 2,
          isApproved: true,
          shopId: 10,
          shopName: 'Căn tin C1–C2',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(home: AuthWrapper()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(ShopOrdersScreen), findsOneWidget);
      expect(find.byType(PendingApprovalScreen), findsNothing);
      expect(find.text('Bảng điều hành'), findsOneWidget);
      expect(find.text('#LF-127'), findsOneWidget);
      expect(find.text('Cơm gà'), findsOneWidget);
      expect(find.text('Tạo đơn thử'), findsNothing);
      final accept = find.text('Nhận đơn');
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mở danh sách'));
      await tester.pumpAndSettle();
      final ready = find.text('Báo xong món');
      await tester.ensureVisible(ready);
      await tester.tap(ready);
      await tester.pumpAndSettle();
      expect(actions, ['shop-accept', 'shop-ready']);
    });

    testWidgets(
      'AuthWrapper routes unapproved Shipper to PendingApprovalScreen',
      (WidgetTester tester) async {
        final mockAuth = MockAuthProvider();
        mockAuth.setMockUser(
          UserModel(
            id: 'shipper_2',
            username: 'shipper_new',
            roleId: 3,
            isApproved: false,
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
              ChangeNotifierProvider<CartProvider>(
                create: (_) => CartProvider(),
              ),
            ],
            child: const MaterialApp(home: AuthWrapper()),
          ),
        );

        expect(find.byType(PendingApprovalScreen), findsOneWidget);
        expect(find.byType(ShipperOrdersScreen), findsNothing);
      },
    );

    testWidgets('AuthWrapper routes approved Shipper to ShipperOrdersScreen', (
      WidgetTester tester,
    ) async {
      final mockAuth = MockAuthProvider();
      mockAuth.setMockUser(
        UserModel(
          id: 'shipper_3',
          username: 'shipper_active',
          roleId: 3,
          isApproved: true,
          shipperId: 5,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(home: AuthWrapper()),
        ),
      );

      expect(find.byType(ShipperOrdersScreen), findsOneWidget);
      expect(find.byType(PendingApprovalScreen), findsNothing);
    });

    testWidgets('AuthWrapper routes normal Student (roleId: 1) to HomeScreen', (
      WidgetTester tester,
    ) async {
      final mockAuth = MockAuthProvider();
      mockAuth.setMockUser(
        UserModel(
          id: 'student_1',
          username: 'sinhvien_1',
          roleId: 1,
          isApproved: true,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuth),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(home: AuthWrapper()),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(PendingApprovalScreen), findsNothing);
    });
  });
}
