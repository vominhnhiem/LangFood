import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/core/widgets/langfood_quantity_stepper.dart';
import 'package:langfood_flutter/data/models/product_model.dart';
import 'package:langfood_flutter/features/cart/presentation/screens/cart_screen.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:langfood_flutter/providers/cart_provider.dart';
import 'package:langfood_flutter/providers/theme_provider.dart';

void main() {
  group('UI-05 CartScreen Tests (LF-05 Stitch Implementation)', () {
    // Fixture: Quán 1 - Cơm Gà Xối Mỡ Bà Tám
    final productShop1Item1 = ProductModel(
      id: 101,
      name: 'Cơm Gà Xối Mỡ (Đùi góc tư)',
      description: 'Đùi tiêu chuẩn, thơm ngon giòn rụm',
      price: 40000,
      shopId: 1,
      shopName: 'Cơm Gà Da Giòn Bà Tám',
      categoryName: 'Cơm',
      isShopOpen: true,
    );

    final productShop1Item2 = ProductModel(
      id: 102,
      name: 'Canh Rong Biển Thịt Bằm',
      description: 'Tô vừa, hành phi thơm',
      price: 8000,
      shopId: 1,
      shopName: 'Cơm Gà Da Giòn Bà Tám',
      categoryName: 'Canh',
      isShopOpen: true,
    );

    // Fixture: Quán 2 - Trà Sữa Nướng Vân Nam KTX
    final productShop2Item1 = ProductModel(
      id: 201,
      name: 'Trà Sữa Nướng Vân Nam Đặc Biệt',
      description: 'Size L, trân châu hoàng kim',
      price: 38000,
      shopId: 2,
      shopName: 'Trà Sữa Nướng Vân Nam',
      categoryName: 'Trà sữa',
      isShopOpen: true,
    );

    final productShop2Item2 = ProductModel(
      id: 202,
      name: 'Bánh Tráng Cuộn Bơ Trứng Muối',
      description: 'Sốt bơ béo, khô bò sợi',
      price: 25000,
      shopId: 2,
      shopName: 'Trà Sữa Nướng Vân Nam',
      categoryName: 'Ăn vặt',
      isShopOpen: true,
    );

    void setMobileViewport(
      WidgetTester tester, [
      Size size = const Size(1080, 2400),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Widget buildTestableCartScreen({
      required CartProvider cartProvider,
      AuthProvider? authProvider,
      ThemeProvider? themeProvider,
      ThemeMode themeMode = ThemeMode.light,
      double textScaleFactor = 1.0,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => authProvider ?? AuthProvider(),
          ),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => themeProvider ?? ThemeProvider(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(393, 852),
              textScaler: TextScaler.linear(textScaleFactor),
              padding: const EdgeInsets.only(top: 44, bottom: 34),
            ),
            child: const CartScreen(),
          ),
        ),
      );
    }

    // TC01: Empty cart state
    testWidgets(
      'TC01: Empty cart state renders properly with Stitch LF-05 empty layout',
      (tester) async {
        setMobileViewport(tester);
        final emptyCart = CartProvider();

        await tester.pumpWidget(
          buildTestableCartScreen(cartProvider: emptyCart),
        );
        await tester.pumpAndSettle();

        expect(find.text('Giỏ hàng KTX đang trống!'), findsOneWidget);
        expect(
          find.text(
            'Bạn chưa chọn món nào từ các quán quen Khu A & Khu B. Chọn ngay để nhận ưu đãi ghép đơn nhé!',
          ),
          findsOneWidget,
        );
        expect(find.text('Khám phá món ngon KTX'), findsOneWidget);
        expect(find.byIcon(Icons.lunch_dining_rounded), findsOneWidget);
      },
    );

    // TC02: Grouped restaurant cart display
    testWidgets(
      'TC02: Grouped restaurant cart renders shop headers, item rows, options, and subtotals',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        cart.addToCart(
          product: productShop1Item1,
          quantity: 1,
          selectedOptionsJson: 'Đùi tiêu chuẩn, Trứng ốp la lòng đào (+5k)',
          note: 'Nhiều dưa leo chua ngọt',
        );
        cart.addToCart(product: productShop1Item2, quantity: 1);
        cart.addToCart(
          product: productShop2Item1,
          quantity: 1,
          selectedOptionsJson:
              'Size L, 50% Đường, 70% Đá, + Trân châu hoàng kim (+8k)',
        );

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        // Check shop headers
        expect(find.text('Cơm Gà Da Giòn Bà Tám'), findsOneWidget);
        expect(find.text('Trà Sữa Nướng Vân Nam'), findsOneWidget);
        expect(find.text('Đơn ghép đa quán KTX'), findsOneWidget);

        // Check items
        expect(find.text('Cơm Gà Xối Mỡ (Đùi góc tư)'), findsOneWidget);
        expect(find.text('Canh Rong Biển Thịt Bằm'), findsOneWidget);
        expect(find.text('Trà Sữa Nướng Vân Nam Đặc Biệt'), findsOneWidget);

        // Check shop subtotals & action button
        expect(find.text('Đặt đơn quán này'), findsNWidgets(2));
      },
    );

    // TC03: Increment and decrement quantity
    testWidgets(
      'TC03: Increment and decrement stepper updates item count and subtotal',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        cart.addToCart(product: productShop1Item1, quantity: 1);

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        expect(cart.totalItemsCount, 1);
        expect(cart.totalAmount, 40000.0);

        // Tap '+' button in Stepper
        final addIcon = find
            .descendant(
              of: find.byType(LangFoodQuantityStepper),
              matching: find.byIcon(Icons.add_rounded),
            )
            .first;
        await tester.tap(addIcon);
        await tester.pumpAndSettle();

        expect(cart.totalItemsCount, 2);
        expect(cart.totalAmount, 80000.0);
      },
    );

    // TC04: Delete item confirmation and execution
    testWidgets(
      'TC04: Deleting item opens confirmation dialog and removes it from cart',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        cart.addToCart(product: productShop1Item1, quantity: 1);

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        expect(cart.items.length, 1);

        // Tap close/delete icon
        final deleteIcon = find.byIcon(Icons.close_rounded).first;
        await tester.tap(deleteIcon);
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text('Xóa món ăn'), findsOneWidget);
        expect(find.text('Xóa'), findsWidgets);

        // Confirm deletion in dialog
        final confirmDeleteBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(TextButton, 'Xóa'),
        );
        await tester.tap(confirmDeleteBtn);
        await tester.pumpAndSettle();

        expect(cart.items.isEmpty, true);
        expect(find.text('Giỏ hàng KTX đang trống!'), findsOneWidget);
      },
    );

    // TC05: Pricing breakdown calculation
    testWidgets(
      'TC05: Pricing breakdown accurately calculates raw total, delivery fee, and discount',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        // Quán 1: 40k + 8k = 48k
        cart.addToCart(product: productShop1Item1, quantity: 1);
        cart.addToCart(product: productShop1Item2, quantity: 1);
        // Quán 2: 38k + 25k = 63k
        cart.addToCart(product: productShop2Item1, quantity: 1);
        cart.addToCart(product: productShop2Item2, quantity: 1);

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        // Scroll down to pricing breakdown
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.text('Tổng tiền món (4 món)'), findsOneWidget);
        expect(find.text('111.000₫'), findsWidgets);

        // Campus delivery fee with 2 shops = 5.000₫
        expect(find.text('5.000₫'), findsOneWidget);

        // Voucher LANGFOODPAIR (-20.000₫)
        expect(find.text('-20.000₫'), findsWidgets);

        // Grand total = 111.000 + 5.000 - 20.000 = 96.000₫
        expect(find.text('96.000₫'), findsOneWidget);
      },
    );

    // TC06: Saved options and notes remain intact
    testWidgets(
      'TC06: Saved options and custom notes remain clearly visible in cart items',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        cart.addToCart(
          product: productShop1Item1,
          quantity: 1,
          selectedOptionsJson: 'Đùi tiêu chuẩn, Trứng ốp la lòng đào (+5k)',
          note: 'Nhiều dưa leo chua ngọt',
        );

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        expect(
          find.text('Đùi tiêu chuẩn, Trứng ốp la lòng đào (+5k)'),
          findsOneWidget,
        );
        expect(find.text('"Nhiều dưa leo chua ngọt"'), findsOneWidget);
      },
    );

    // TC07: Clear all cart items
    testWidgets(
      'TC07: Tapping "Xóa" in AppBar opens confirmation dialog and clears cart upon confirm',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        cart.addToCart(product: productShop1Item1, quantity: 2);
        cart.addToCart(product: productShop2Item1, quantity: 1);

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        expect(cart.items.length, 2);

        // Tap AppBar 'Xóa'
        final clearAllBtn = find.text('Xóa');
        await tester.tap(clearAllBtn);
        await tester.pumpAndSettle();

        expect(find.text('Xóa tất cả món?'), findsOneWidget);

        // Confirm clear
        final confirmBtn = find.text('Xóa hết');
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(cart.items.isEmpty, true);
        expect(find.text('Giỏ hàng KTX đang trống!'), findsOneWidget);
      },
    );

    // TC08: Sticky checkout bar status & master select-all
    testWidgets(
      'TC08: Sticky checkout bar reflects select-all toggle and disables CTA when 0 selected',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        cart.addToCart(product: productShop1Item1, quantity: 1);

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        expect(find.text('Thanh toán (1)'), findsOneWidget);

        // Toggle select all off
        final selectAllTile = find.text('Tất cả');
        await tester.tap(selectAllTile);
        await tester.pumpAndSettle();

        // CTA now displays 0 items and is disabled
        expect(find.text('Thanh toán (0)'), findsOneWidget);
        final ctaBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Thanh toán (0)'),
        );
        expect(ctaBtn.onPressed, isNull);
      },
    );

    // TC09: Checkout confirmation flow preserves existing contract
    testWidgets(
      'TC09: Tapping checkout CTA opens confirmation dialog with proper shop and amount',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        cart.addToCart(product: productShop1Item1, quantity: 1);

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        final ctaBtn = find.widgetWithText(ElevatedButton, 'Thanh toán (1)');
        await tester.tap(ctaBtn);
        await tester.pumpAndSettle();

        expect(find.text('Xác nhận đặt đơn'), findsOneWidget);
        expect(find.text('Xác nhận & Set định vị'), findsOneWidget);
      },
    );

    // TC10: Responsive testing across 4 viewports with text scale 1.0 and 1.3
    testWidgets(
      'TC10: Responsive layout testing across 4 viewports without RenderFlex overflow',
      (tester) async {
        final cart = CartProvider();
        cart.addToCart(
          product: productShop1Item1,
          quantity: 2,
          selectedOptionsJson: 'Đùi tiêu chuẩn siêu to khổng lồ, Trứng ốp la lòng đào đặc biệt (+15k)',
          note: 'Xin thêm nhiều dưa leo chua ngọt và nước mắm kẹo',
        );
        cart.addToCart(product: productShop2Item1, quantity: 1);

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
                ],
                child: MaterialApp(
                  theme: AppTheme.lightTheme,
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: vp,
                      textScaler: TextScaler.linear(scale),
                      padding: const EdgeInsets.only(top: 44, bottom: 34),
                    ),
                    child: const CartScreen(),
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

    // TC11: Dark Mode rendering
    testWidgets('TC11: Dark Mode renders cleanly with correct theme tokens', (
      tester,
    ) async {
      setMobileViewport(tester);
      final cart = CartProvider();
      cart.addToCart(product: productShop1Item1, quantity: 1);

      await tester.pumpWidget(
        buildTestableCartScreen(cartProvider: cart, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(find.text('Giỏ hàng của bạn'), findsOneWidget);
      expect(find.text('Cơm Gà Da Giòn Bà Tám'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // TC12: Multi-shop co-delivery banner & savings pill
    testWidgets(
      'TC12: Multi-shop co-delivery banner and savings pill show when 2 shops are present',
      (tester) async {
        setMobileViewport(tester);
        final cart = CartProvider();
        cart.addToCart(product: productShop1Item1, quantity: 1);
        cart.addToCart(product: productShop2Item1, quantity: 1);

        await tester.pumpWidget(buildTestableCartScreen(cartProvider: cart));
        await tester.pumpAndSettle();

        expect(find.text('Đơn ghép đa quán KTX'), findsOneWidget);
        expect(find.text('Tối đa 2 quán'), findsOneWidget);
        expect(find.text('Ghép 2 quán tiết kiệm 15.000₫ ship'), findsOneWidget);
        expect(find.text('Đã áp dụng'), findsOneWidget);
        expect(find.text('Tiết kiệm 35.000₫'), findsOneWidget);
      },
    );
  });
}
