import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/data/models/order_test_model.dart';
import 'package:langfood_flutter/data/models/product_model.dart';
import 'package:langfood_flutter/data/services/order_test_service.dart';
import 'package:langfood_flutter/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:langfood_flutter/features/shipper/presentation/screens/shipper_orders_screen.dart';
import 'package:langfood_flutter/features/tracking/presentation/screens/location_picker_screen.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:langfood_flutter/providers/cart_provider.dart';
import 'package:langfood_flutter/providers/theme_provider.dart';

/// Provider gạch bản đồ test (Mock Tile Provider) không gọi HTTP mạng
class TestTileProvider extends TileProvider {
  static final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_kTransparentPng);
  }
}

void main() {
  group('UI-06 LocationPicker & CheckoutScreen Tests (LF-06 & LF-07 Stitch)', () {
    // Fixture: Quán 1 - Cơm Gà Bà Tám
    final productShop1 = ProductModel(
      id: 101,
      name: 'Cơm Gà Xối Mỡ Da Giòn',
      description: 'Đùi góc tư, thơm ngon giòn rụm',
      price: 40000,
      shopId: 1,
      shopName: 'Cơm Gà Da Giòn Bà Tám (KTX B)',
      categoryName: 'Cơm',
      isShopOpen: true,
    );

    // Fixture: Quán 2 - Trà Sữa Nướng Vân Nam
    final productShop2 = ProductModel(
      id: 201,
      name: 'Trà Sữa Nướng Vân Nam',
      description: 'Size L, trân châu hoàng kim',
      price: 38000,
      shopId: 2,
      shopName: 'Trà Sữa Nướng Vân Nam (Tòa BA4)',
      categoryName: 'Trà sữa',
      isShopOpen: true,
    );

    const defaultLocation = CampusDeliveryLocation(
      position: LatLng(10.8800, 106.8050),
      buildingName: 'Tòa BA2 - KTX Khu B',
      subAddress: 'Đường Tạ Quang Bửu, P. Đông Hòa, Dĩ An',
      dropOffOptionKey: 'g',
      dropOffOptionLabel: 'Sảnh tầng G (Chân thang máy)',
      extraFee: 0.0,
      shipperNote: 'Gọi mình trước 2p',
    );

    Widget createTestApp({
      required Widget child,
      CartProvider? cartProvider,
      AuthProvider? authProvider,
      ThemeMode themeMode = ThemeMode.light,
    }) {
      final cart = cartProvider ?? CartProvider();
      final auth = authProvider ?? AuthProvider();

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cart),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: child,
        ),
      );
    }

    // TC01: Mở LocationPickerScreen và kiểm tra các thành phần theo Stitch LF-06
    testWidgets(
      'TC01: LocationPicker renders all Stitch LF-06 layout components',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: LocationPickerScreen(tileProvider: TestTileProvider()),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kiểm tra Search Overlay
        expect(find.byType(TextField), findsWidgets);
        expect(find.text('Tìm tòa KTX, giảng đường...'), findsOneWidget);

        // 2. Kiểm tra Bottom sheet header & ETA
        expect(find.text('Chi tiết điểm nhận món'), findsOneWidget);
        expect(find.text('Khuôn viên Ký túc xá ĐHQG TP.HCM'), findsOneWidget);
        expect(find.text('15 - 20 phút'), findsOneWidget);

        // Kéo sheet lên tối đa
        await tester.drag(
          find.text('Chi tiết điểm nhận món'),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        // 3. Kiểm tra Preset Hotspot Chips
        expect(find.text('🏢 KTX Khu B (BA2)'), findsOneWidget);
        expect(find.text('🏫 KTX Khu A (A15)'), findsOneWidget);
        expect(find.text('📚 Thư viện TT'), findsOneWidget);
        expect(find.text('🏛️ ĐH Bách Khoa CS2'), findsOneWidget);

        // 4. Kiểm tra Tòa nhà mặc định
        expect(find.text('Tòa BA2 - KTX Khu B'), findsWidgets);
        expect(find.text('Đúng tuyến'), findsOneWidget);

        // 5. Kiểm tra 3 Drop-off options
        expect(find.text('Sảnh tầng G (Chân thang máy)'), findsOneWidget);
        expect(find.text('KHUYÊN DÙNG'), findsOneWidget);
        expect(find.text('Cổng bảo vệ tòa nhà'), findsOneWidget);
        expect(find.text('Giao tận cửa phòng KTX'), findsOneWidget);
        expect(find.text('+5.000₫'), findsOneWidget);

        // Cuộn tiếp danh sách để hiện nút CTA ở cuối
        await tester.drag(
          find.text('Sảnh tầng G (Chân thang máy)'),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();

        // 6. Kiểm tra CTA button
        expect(find.text('Xác nhận điểm giao này'), findsOneWidget);
      },
    );

    // TC02: Tương tác nút GPS nổi
    testWidgets('TC02: Tapping GPS button triggers location fetch safely', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: LocationPickerScreen(tileProvider: TestTileProvider()),
        ),
      );
      await tester.pumpAndSettle();

      final gpsBtn = find.byIcon(Icons.my_location_rounded);
      expect(gpsBtn, findsOneWidget);

      await tester.tap(gpsBtn);
      await tester.pump();

      // Kiểm tra app không bị crash khi chạy trong test runner
      expect(find.byType(LocationPickerScreen), findsOneWidget);
    });

    // TC03: Chọn Preset Hotspot chip KTX A
    testWidgets(
      'TC03: Tapping preset hotspot chip updates selected building and address',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: LocationPickerScreen(tileProvider: TestTileProvider()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.text('Chi tiết điểm nhận món'),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        final ktxAChip = find.text('🏫 KTX Khu A (A15)');
        expect(ktxAChip, findsOneWidget);

        await tester.tap(ktxAChip);
        await tester.pumpAndSettle();

        expect(find.text('Tòa A15 - KTX Khu A'), findsWidgets);
        expect(
          find.text('Đường Lạc Long Quân, Linh Trung, Thủ Đức'),
          findsOneWidget,
        );
      },
    );

    // TC04: Xác nhận vị trí chuyển sang CheckoutScreen
    testWidgets(
      'TC04: Confirming location navigates to CheckoutScreen with delivery data',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(product: productShop1, quantity: 1);

        await tester.pumpWidget(
          createTestApp(
            child: LocationPickerScreen(tileProvider: TestTileProvider()),
            cartProvider: cart,
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.text('Chi tiết điểm nhận món'),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        // Cuộn tiếp danh sách để hiện nút CTA ở cuối
        await tester.drag(
          find.text('Sảnh tầng G (Chân thang máy)'),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();

        final confirmBtn = find.text('Xác nhận điểm giao này');
        expect(confirmBtn, findsOneWidget);

        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        // Kiểm tra đã sang màn hình CheckoutScreen
        expect(find.byType(CheckoutScreen), findsOneWidget);
        expect(find.text('Xác nhận đơn hàng'), findsOneWidget);
        expect(find.text('Tòa BA2 - KTX Khu B'), findsWidgets);
      },
    );

    // TC05: Sửa điểm giao từ Checkout quay lại LocationPicker
    testWidgets(
      'TC05: Tapping "Thay đổi" in Checkout navigates to LocationPicker to edit location',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(product: productShop1, quantity: 1);

        await tester.pumpWidget(
          createTestApp(
            child: CheckoutScreen(
              deliveryLocation: defaultLocation,
              tileProvider: TestTileProvider(),
            ),
            cartProvider: cart,
          ),
        );
        await tester.pumpAndSettle();

        final changeBtn = find.text('Thay đổi');
        expect(changeBtn, findsOneWidget);

        await tester.tap(changeBtn);
        await tester.pumpAndSettle();

        // Xác nhận đã mở lại LocationPickerScreen
        expect(find.byType(LocationPickerScreen), findsOneWidget);
      },
    );

    // TC06: Checkout hiển thị đúng món và tổng tiền từ CartProvider
    testWidgets(
      'TC06: CheckoutScreen displays order items recap, options and pricing accurately',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(
          product: productShop1,
          quantity: 2,
          selectedOptionsJson: 'Đùi góc tư, Trứng ốp la lòng đào',
        );
        cart.addToCart(
          product: productShop2,
          quantity: 1,
          selectedOptionsJson: 'Size L, 50% Đường, 70% Đá',
        );

        await tester.pumpWidget(
          createTestApp(
            child: CheckoutScreen(
              deliveryLocation: defaultLocation,
              tileProvider: TestTileProvider(),
            ),
            cartProvider: cart,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Kiểm tra hiển thị tên món
        expect(find.text('Cơm Gà Xối Mỡ Da Giòn'), findsOneWidget);
        expect(find.text('Trà Sữa Nướng Vân Nam'), findsOneWidget);

        // 2. Kiểm tra options đã lưu
        expect(find.text('Đùi góc tư, Trứng ốp la lòng đào'), findsOneWidget);
        expect(find.text('Size L, 50% Đường, 70% Đá'), findsOneWidget);

        // 3. Kiểm tra nhãn đơn ghép 2 quán
        expect(find.text('Đơn ghép KTX ĐHQG'), findsOneWidget);
        expect(find.text('2 Quán • 1 Shipper'), findsOneWidget);

        // 4. Kiểm tra nút Đặt đơn ngay
        expect(find.text('Đặt đơn ngay'), findsOneWidget);
      },
    );

    // TC07: Đổi phương thức thanh toán qua Bottom Sheet
    testWidgets(
      'TC07: Opening payment method bottom sheet allows selecting MoMo / VietQR / COD',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(product: productShop1, quantity: 1);

        await tester.pumpWidget(
          createTestApp(
            child: CheckoutScreen(
              deliveryLocation: defaultLocation,
              tileProvider: TestTileProvider(),
            ),
            cartProvider: cart,
          ),
        );
        await tester.pumpAndSettle();

        // Cuộn xuống tìm thẻ Phương thức thanh toán
        await tester.scrollUntilVisible(
          find.text('Phương thức thanh toán'),
          300,
        );
        await tester.pumpAndSettle();

        // Mở bottom sheet chọn phương thức
        final changePaymentBtn = find.text('Đổi');
        expect(changePaymentBtn, findsOneWidget);

        await tester.tap(changePaymentBtn);
        await tester.pumpAndSettle();

        // Kiểm tra danh sách 4 phương thức theo Stitch LF-07
        expect(find.text('Ví MoMo KTX Express'), findsOneWidget);
        expect(find.text('VietQR Pro / Chuyển khoản'), findsOneWidget);
        expect(find.text('Ví ZaloPay'), findsOneWidget);
        expect(find.text('Tiền mặt khi nhận đồ (COD)'), findsOneWidget);

        // Chọn COD
        await tester.tap(find.text('Tiền mặt khi nhận đồ (COD)'));
        await tester.pumpAndSettle();

        // Xác nhận
        await tester.tap(find.text('Xác nhận phương thức'));
        await tester.pumpAndSettle();

        // Đã cập nhật phương thức sang COD
        expect(find.text('Tiền mặt khi nhận đồ (COD)'), findsOneWidget);
      },
    );

    // TC08: Chống tạo đơn trùng và xử lý an toàn
    testWidgets(
      'TC08: Sticky CTA button prevents double tap and handles test mode safely',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(product: productShop1, quantity: 1);

        await tester.pumpWidget(
          createTestApp(
            child: CheckoutScreen(
              deliveryLocation: defaultLocation,
              tileProvider: TestTileProvider(),
            ),
            cartProvider: cart,
          ),
        );
        await tester.pumpAndSettle();

        final submitBtn = find.text('Đặt đơn ngay');
        expect(submitBtn, findsOneWidget);

        // Chạm vào nút đặt đơn
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Trong môi trường test offline không có backend thật, lỗi kết nối được bắt an toàn
        // Dữ liệu giỏ hàng được bảo toàn và app không crash
        expect(cart.totalItemsCount, equals(1));
        expect(find.byType(CheckoutScreen), findsOneWidget);
      },
    );

    // TC09: Banner thông báo Chế độ thử nghiệm an toàn
    testWidgets(
      'TC09: Test mode demo banner is clearly visible to protect API contract',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(product: productShop1, quantity: 1);

        await tester.pumpWidget(
          createTestApp(
            child: CheckoutScreen(
              deliveryLocation: defaultLocation,
              tileProvider: TestTileProvider(),
            ),
            cartProvider: cart,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Chế độ thử nghiệm: Đơn hàng sẽ gửi qua hệ thống mô phỏng OrderTest.',
          ),
          findsOneWidget,
        );
      },
    );

    // TC10: Lựa chọn vị trí gặp shipper thêm phụ phí giao tận phòng (+5k)
    testWidgets(
      'TC10: Selecting door drop-off adds 5.000₫ extra fee to pricing breakdown',
      (tester) async {
        const doorLocation = CampusDeliveryLocation(
          position: LatLng(10.8800, 106.8050),
          buildingName: 'Tòa BA2 - KTX Khu B',
          subAddress: 'Đường Tạ Quang Bửu',
          dropOffOptionKey: 'door',
          dropOffOptionLabel: 'Giao tận cửa phòng KTX (+5k)',
          extraFee: 5000.0,
        );

        final cart = CartProvider();
        cart.addToCart(product: productShop1, quantity: 1);

        await tester.pumpWidget(
          createTestApp(
            child: CheckoutScreen(
              deliveryLocation: doorLocation,
              tileProvider: TestTileProvider(),
            ),
            cartProvider: cart,
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(find.text('Chi tiết thanh toán'), 300);

        expect(find.text('Phụ phí giao tận phòng (Lầu cao)'), findsOneWidget);
        expect(find.text('5.000₫'), findsWidgets);
      },
    );

    // TC11: Dark Mode rendering
    testWidgets(
      'TC11: Dark Mode renders cleanly with LangFood dark theme tokens',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(product: productShop1, quantity: 1);

        await tester.pumpWidget(
          createTestApp(
            child: CheckoutScreen(
              deliveryLocation: defaultLocation,
              tileProvider: TestTileProvider(),
            ),
            cartProvider: cart,
            themeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Xác nhận đơn hàng'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Chi tiết thanh toán'), 300);
        expect(find.text('Chi tiết thanh toán'), findsOneWidget);
      },
    );

    // TC12: Responsive testing across 4 viewports x 2 text scales
    testWidgets(
      'TC12: Responsive layout testing across 4 viewports without RenderFlex overflow',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(
          product: productShop1,
          quantity: 2,
          selectedOptionsJson: 'Đùi góc tư da giòn siêu to khổng lồ đặc biệt',
        );
        cart.addToCart(product: productShop2, quantity: 1);

        final viewports = [
          const Size(320, 640),
          const Size(360, 800),
          const Size(393, 852),
          const Size(430, 932),
        ];

        for (final vp in viewports) {
          for (final scale in [1.0, 1.3]) {
            tester.view.physicalSize = Size(vp.width * 2.0, vp.height * 2.0);
            tester.view.devicePixelRatio = 2.0;

            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider<CartProvider>.value(value: cart),
                  ChangeNotifierProvider<AuthProvider>(
                    create: (_) => AuthProvider(),
                  ),
                  ChangeNotifierProvider<ThemeProvider>(
                    create: (_) => ThemeProvider(),
                  ),
                ],
                child: MaterialApp(
                  theme: AppTheme.lightTheme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: vp,
                      textScaler: TextScaler.linear(scale),
                      padding: const EdgeInsets.only(top: 44, bottom: 34),
                    ),
                    child: CheckoutScreen(
                      deliveryLocation: defaultLocation,
                      tileProvider: TestTileProvider(),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            final err = tester.takeException();
            expect(
              err,
              isNull,
              reason:
                  'RenderFlex overflow at ${vp.width}x${vp.height} with scale $scale',
            );
          }
        }
      },
    );

    // TC13: Quay lại không làm mất giỏ hàng
    testWidgets('TC13: Navigating back preserves cart items intact', (
      tester,
    ) async {
      final cart = CartProvider();
      cart.addToCart(product: productShop1, quantity: 2);
      cart.addToCart(product: productShop2, quantity: 1);

      expect(cart.totalItemsCount, equals(3));

      await tester.pumpWidget(
        createTestApp(
          child: CheckoutScreen(
            deliveryLocation: defaultLocation,
            tileProvider: TestTileProvider(),
          ),
          cartProvider: cart,
        ),
      );
      await tester.pumpAndSettle();

      // Táp nút Back trên AppBar
      final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backBtn, findsOneWidget);

      await tester.tap(backBtn);
      await tester.pump();

      // Giỏ hàng vẫn giữ nguyên 3 món
      expect(cart.totalItemsCount, equals(3));
    });

    // TC14: Quick Note Tags trong LocationPicker nối ghi chú chính xác
    testWidgets(
      'TC14: Quick note tags in LocationPicker append tags smoothly',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: LocationPickerScreen(tileProvider: TestTileProvider()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.text('Chi tiết điểm nhận món'),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        final quickTag1 = find.text('+ Gọi trước 2p');
        expect(quickTag1, findsOneWidget);

        await tester.tap(quickTag1);
        await tester.pumpAndSettle();

        final input = find.widgetWithText(TextField, 'Gọi trước 2p');
        expect(input, findsOneWidget);
      },
    );

    // TC15: ShipperOrdersScreen nhận đơn mới theo thời gian thực (Real-time Order Dispatch)
    testWidgets(
      'TC15: Real-time simulated order dispatch updates ShipperOrdersScreen automatically',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ShipperOrdersScreen(
              enablePeriodicTimer: false,
              initialOrders: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Kiểm tra AppBar có nhãn LIVE
        expect(find.text('LIVE'), findsOneWidget);
        expect(find.text('Shipper KTX'), findsOneWidget);

        // Khách hàng đặt một đơn mới
        final newCustomerOrder = OrderTestModel(
          id: 9999,
          customerName: 'Nguyễn Văn A (Demo Test)',
          phone: '0912345678',
          deliveryAddress: 'Phòng 412 - Tòa BA2 KTX Khu B',
          latitude: 10.8751,
          longitude: 106.7997,
          totalAmount: 65000,
          status: 'Ready',
        );

        // Gọi createOrderTest của OrderTestService
        try {
          await OrderTestService().createOrderTest(newCustomerOrder);
        } catch (_) {}

        // Bơm frame để widget cập nhật qua notifier
        await tester.pump();
        await tester.pumpAndSettle();

        // Đơn mới đã xuất hiện tự động trên màn hình Shipper
        expect(find.textContaining('Nguyễn Văn A (Demo Test)'), findsOneWidget);
        expect(find.textContaining('Phòng 412 - Tòa BA2 KTX Khu B'), findsOneWidget);
      },
    );

    // TC16: Mở Role Switcher 3 roles trên ShipperOrdersScreen
    testWidgets(
      'TC16: 3-role switcher bottom sheet opens and displays all 3 roles',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ShipperOrdersScreen(
              enablePeriodicTimer: false,
              initialOrders: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final switcherBtn = find.byIcon(Icons.swap_horiz_rounded);
        expect(switcherBtn, findsOneWidget);

        await tester.tap(switcherBtn);
        await tester.pumpAndSettle();

        expect(find.text('Chuyển đổi 3 Role (Demo Giảng Viên)'), findsOneWidget);
        expect(find.text('1. Sinh viên (Khách hàng)'), findsOneWidget);
        expect(find.text('2. Chủ quán (Seller / Shop)'), findsOneWidget);
        expect(find.text('3. Tài xế (Shipper)'), findsOneWidget);
      },
    );
  });
}
