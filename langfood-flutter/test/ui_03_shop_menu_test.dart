import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/core/widgets/langfood_empty_state.dart';
import 'package:langfood_flutter/core/widgets/langfood_floating_cart_pill.dart';
import 'package:langfood_flutter/data/models/product_model.dart';
import 'package:langfood_flutter/data/models/shop_model.dart';
import 'package:langfood_flutter/features/food_detail/presentation/screens/food_detail_screen.dart';
import 'package:langfood_flutter/features/shop/presentation/screens/shop_menu_screen.dart';
import 'package:langfood_flutter/features/shop/presentation/widgets/shop_product_card.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:langfood_flutter/providers/cart_provider.dart';
import 'package:langfood_flutter/providers/theme_provider.dart';

void main() {
  group('UI-03 ShopMenuScreen Tests (LF-02 Stitch Implementation)', () {
    final mockShop = ShopModel(
      id: 1,
      name: 'Cơm Gà Xối Mỡ Bà Tám',
      description: 'Đùi gà da giòn rụm • Cơm chiên sốt cà chua gia truyền',
      address: 'Cổng sau ĐH Khoa Học Tự Nhiên, KTX Khu B',
      rating: 4.9,
      reviewCount: 120,
      prepTime: '15-20 phút',
      distance: '350m từ KTX B',
      isOpen: true,
    );

    final mockProducts = [
      ProductModel(
        id: 101,
        name: 'Cơm Đùi Gà Xối Mỡ Da Giòn',
        description:
            'Đùi gà góc tư chiên giòn, cơm đảo sốt cà chua, dưa leo chua ngọt',
        price: 35000,
        imageUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        shopId: 1,
        shopName: 'Cơm Gà Xối Mỡ Bà Tám',
        categoryName: 'Cơm gà',
        isShopOpen: true,
      ),
      ProductModel(
        id: 102,
        name: 'Cơm Cánh Gà Sốt Nước Mắm',
        description: 'Cánh gà đậm đà nước mắm tỏi ớt, ăn kèm canh rong biển',
        price: 32000,
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
        shopId: 1,
        shopName: 'Cơm Gà Xối Mỡ Bà Tám',
        categoryName: 'Cơm gà',
        isShopOpen: true,
      ),
      ProductModel(
        id: 103,
        name: 'Trà Tắc Xí Muội Khổng Lồ',
        description: 'Ly 700ml chua ngọt giải ngấy cực đã cho sinh viên',
        price: 15000,
        imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=400',
        shopId: 1,
        shopName: 'Cơm Gà Xối Mỡ Bà Tám',
        categoryName: 'Nước uống',
        isShopOpen: true,
      ),
    ];

    Widget buildTestableShopMenuScreen({
      ShopModel? shop,
      List<ProductModel>? products,
      CartProvider? cartProvider,
      AuthProvider? authProvider,
      ThemeProvider? themeProvider,
      ThemeMode themeMode = ThemeMode.light,
      double textScaleFactor = 1.0,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CartProvider>(
            create: (_) => cartProvider ?? CartProvider(),
          ),
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
            ),
            child: ShopMenuScreen(
              shopId: 1,
              initialShopName: shop?.name ?? 'Cơm Gà Xối Mỡ Bà Tám',
              initialShop: shop ?? mockShop,
              initialProducts: products ?? mockProducts,
            ),
          ),
        ),
      );
    }

    testWidgets('1. Shop Menu renders all LF-02 key elements correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShopMenuScreen());
      await tester.pumpAndSettle();

      // Restaurant Identity Header
      expect(find.text('Cơm Gà Xối Mỡ Bà Tám'), findsWidgets);
      expect(find.textContaining('Đùi gà da giòn rụm'), findsOneWidget);
      expect(
        find.text('Cổng sau ĐH Khoa Học Tự Nhiên, KTX Khu B'),
        findsOneWidget,
      );
      expect(find.text('4.9'), findsWidgets);
      expect(find.text('15-20 phút'), findsWidgets);
      expect(find.text('Freeship KTX'), findsWidgets);

      // Voucher Card
      expect(find.textContaining('SINHVIENKHOE'), findsOneWidget);
      expect(find.text('Dùng ngay'), findsOneWidget);

      // Campus notice
      expect(find.textContaining('Đặc quyền KTX'), findsOneWidget);

      // Category filter chips
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Cơm gà'), findsWidgets);
      expect(find.text('Nước uống'), findsOneWidget);

      // Products rendered
      expect(find.text('Cơm Đùi Gà Xối Mỡ Da Giòn'), findsOneWidget);
      expect(find.text('Cơm Cánh Gà Sốt Nước Mắm'), findsOneWidget);
      expect(find.byType(ShopProductCard), findsNWidgets(3));

      // Trust footer badge
      expect(find.text('Quán ăn Đối tác Đảm bảo LangFood'), findsOneWidget);
    });

    testWidgets('2. Category filter filters product list smoothly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShopMenuScreen());
      await tester.pumpAndSettle();

      // Initially all 3 products are visible
      expect(find.byType(ShopProductCard), findsNWidgets(3));

      // Tap 'Nước uống' category chip
      final waterCategory = find.text('Nước uống');
      expect(waterCategory, findsOneWidget);
      await tester.tap(waterCategory);
      await tester.pumpAndSettle();

      // Only 1 drink product should remain
      expect(find.byType(ShopProductCard), findsOneWidget);
      expect(find.text('Trà Tắc Xí Muội Khổng Lồ'), findsOneWidget);
      expect(find.text('Cơm Đùi Gà Xối Mỡ Da Giòn'), findsNothing);

      // Tap 'Tất cả' again
      await tester.tap(find.text('Tất cả'));
      await tester.pumpAndSettle();

      // All 3 back
      expect(find.byType(ShopProductCard), findsNWidgets(3));
    });

    testWidgets('3. Search bar filters product cards in real-time', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShopMenuScreen());
      await tester.pumpAndSettle();

      // Find search action button in header
      final searchButton = find.byIcon(Icons.search_rounded);
      expect(searchButton, findsOneWidget);
      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // Enter query
      await tester.enterText(find.byType(TextField), 'Trà tắc');
      await tester.pumpAndSettle();

      // Filtered to only 1 item
      expect(find.byType(ShopProductCard), findsOneWidget);
      expect(find.text('Trà Tắc Xí Muội Khổng Lồ'), findsOneWidget);
    });

    testWidgets('4. Tapping product card opens FoodDetailScreen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShopMenuScreen());
      await tester.pumpAndSettle();

      // Tap first card
      final firstProduct = find.text('Cơm Đùi Gà Xối Mỡ Da Giòn');
      await tester.tap(firstProduct);
      await tester.pumpAndSettle();

      // Verify FoodDetailScreen pushed
      expect(find.byType(FoodDetailScreen), findsOneWidget);
    });

    testWidgets('5. Floating Cart Pill appears when cart has items', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = CartProvider();

      await tester.pumpWidget(
        buildTestableShopMenuScreen(cartProvider: cartProvider),
      );
      await tester.pumpAndSettle();

      // Initially empty -> no floating cart pill
      expect(find.byType(LangFoodFloatingCartPill), findsNothing);

      // Add item to cart
      cartProvider.addToCart(product: mockProducts[0], quantity: 1);
      await tester.pumpAndSettle();

      // Floating Cart Pill should now be visible
      expect(find.byType(LangFoodFloatingCartPill), findsOneWidget);
      expect(find.text('1 món'), findsOneWidget);
      expect(find.text('Xem giỏ quán'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LangFoodFloatingCartPill),
          matching: find.textContaining('35.000'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('6. Empty state displays cleanly when shop has no products', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableShopMenuScreen(products: []));
      await tester.pumpAndSettle();

      expect(find.byType(LangFoodEmptyState), findsOneWidget);
      expect(find.text('Quán chưa cập nhật thực đơn'), findsOneWidget);
    });

    testWidgets('7. Long text does not cause RenderFlex overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final longShop = ShopModel(
        id: 99,
        name: 'Quán Cơm Gà Xối Mỡ Da Giòn Sốt Nước Mắm Tỏi Ớt Siêu Cay Khổng Lồ KTX Đại Học Quốc Gia TP.HCM',
        description: 'Đùi gà chiên giòn rụm với công thức bí truyền 30 năm kết hợp cùng cơm chiên tỏi và nước sốt mật ong thơm lừng',
        address: 'Đường A2, Khu Phố 6, Phường Linh Trung, Thành phố Thủ Đức, Ký túc xá Khu B Đại học Quốc Gia TP.HCM',
        rating: 4.98,
        prepTime: '25-30 phút',
        distance: '1.2km từ cổng chính',
        isOpen: true,
      );

      final longProduct = ProductModel(
        id: 999,
        name: 'Cơm Đùi Gà Góc Tư Chiên Xối Mỡ Sốt Tỏi Ớt Chua Ngọt Kèm Canh Rong Biển Thịt Bằm Và Kim Chi Hàn Quốc Đặc Biệt',
        description: 'Phần cơm siêu to khổng lồ dành cho 2 bạn sinh viên ăn chung tiết kiệm chi phí mùa thi cử kèm sốt chấm cay ngọt',
        price: 999000,
        imageUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        shopId: 99,
        shopName: longShop.name,
        categoryName: 'Món đặc biệt',
        isShopOpen: true,
      );

      await tester.pumpWidget(
        buildTestableShopMenuScreen(shop: longShop, products: [longProduct]),
      );
      await tester.pumpAndSettle();

      // Zero exceptions and card rendered
      expect(tester.takeException(), isNull);
      expect(find.byType(ShopProductCard), findsOneWidget);
    });

    testWidgets('8. Responsive layout test across standard viewports', (
      WidgetTester tester,
    ) async {
      final viewports = [
        const Size(320, 640), // iPhone SE / Small Android
        const Size(360, 800), // Standard Android
        const Size(393, 852), // iPhone 15 / 16
        const Size(430, 932), // iPhone 15 Pro Max
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = Size(vp.width, vp.height);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CartProvider>(
                create: (_) => CartProvider(),
              ),
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
                data: MediaQueryData(size: vp),
                child: ShopMenuScreen(
                  shopId: 1,
                  initialShop: mockShop,
                  initialProducts: mockProducts,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on viewport $vp',
        );
        expect(find.byType(ShopMenuScreen), findsOneWidget);
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('9. Text scaling (1.3x) does not cause RenderFlex overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableShopMenuScreen(textScaleFactor: 1.3),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ShopMenuScreen), findsOneWidget);
    });

    testWidgets('10. Dark Mode renders cleanly with correct theme tokens', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestableShopMenuScreen(themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ShopMenuScreen), findsOneWidget);
      expect(find.text('Cơm Gà Xối Mỡ Bà Tám'), findsWidgets);
    });

    testWidgets(
      '11. Non-demo shop from backend renders "Quán mới" and omits fake voucher',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final realShop = ShopModel(
          id: 2,
          name: 'Cơm Tấm & Bún Bò Làng Đại Học',
          address: 'Khu B ĐHQG TP.HCM',
          isOpen: true,
        );

        await tester.pumpWidget(
          buildTestableShopMenuScreen(shop: realShop, products: mockProducts),
        );
        await tester.pumpAndSettle();

        // Verify "Quán mới" is rendered instead of fake rating 4.9
        expect(find.text('Quán mới'), findsOneWidget);
        expect(find.text('4.9'), findsNothing);
        expect(find.textContaining('1200+ đánh giá'), findsNothing);

        // Verify fake voucher "SINHVIENKHOE" is NOT rendered
        expect(find.textContaining('SINHVIENKHOE'), findsNothing);

        // Verify non-verified shop does NOT have fake verified badge
        expect(find.text('Quán quen KTX'), findsNothing);

        // Verify real address is displayed
        expect(find.text('Khu B ĐHQG TP.HCM'), findsOneWidget);
      },
    );
  });
}
