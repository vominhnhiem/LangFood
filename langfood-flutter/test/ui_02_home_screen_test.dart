import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/core/widgets/langfood_floating_cart_pill.dart';
import 'package:langfood_flutter/core/widgets/langfood_horizontal_product_card.dart';
import 'package:langfood_flutter/features/home/presentation/screens/home_screen.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:langfood_flutter/providers/cart_provider.dart';
import 'package:langfood_flutter/providers/theme_provider.dart';

void main() {
  group('UI-02 HomeScreen Tests (LF-01 Stitch Implementation)', () {
    Widget buildTestableHomeScreen({
      CartProvider? cartProvider,
      AuthProvider? authProvider,
      ThemeProvider? themeProvider,
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
          themeMode: ThemeMode.light,
          home: const HomeScreen(),
        ),
      );
    }

    testWidgets('HomeScreen renders all key LF-01 sections properly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Brand Title
      expect(find.text('LANGFOOD'), findsOneWidget);
      expect(find.text('Khám Phá'), findsOneWidget);

      // 2. Location Bar & Greeting
      expect(find.text('GIAO TẬN PHÒNG THI & KTX'), findsOneWidget);
      expect(find.text('Hôm nay ăn gì ở Làng? 🍜'), findsOneWidget);

      // 3. Search Bar
      expect(find.text('Tìm cơm gà, trà sữa nướng, bún bò...'), findsOneWidget);

      // 4. Quick Action Pills
      expect(find.text('Đặt nhóm chia ship'), findsOneWidget);
      expect(find.text('Quán quen KTX'), findsOneWidget);
      expect(find.text('Dưới 30k'), findsOneWidget);
      expect(find.text('Freeship 0đ'), findsWidgets);

      // 5. Category Section
      expect(find.text('Danh mục món ngon'), findsOneWidget);

      // 6. Flash Deals Section
      expect(find.text('Deal chớp nhoáng nghỉ trưa'), findsOneWidget);

      // 7. Vibe Filter Section
      expect(find.text('Quán ngon sinh viên chấm cao 🌟'), findsOneWidget);
      expect(find.text('Gần KTX (≤ 500m)'), findsOneWidget);
      expect(find.text('Đánh giá 4.8+ ⭐'), findsOneWidget);

      // 8. Bottom Navigation
      expect(find.text('Khám phá'), findsOneWidget);
      expect(find.text('Đơn hàng'), findsOneWidget);
      expect(find.text('Đặt chung'), findsOneWidget);
      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Tài khoản'), findsOneWidget);
    });

    testWidgets('Floating Cart Pill appears when cart has items', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cartProvider = CartProvider();

      await tester.pumpWidget(
        buildTestableHomeScreen(cartProvider: cartProvider),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Initially empty -> no floating cart pill
      expect(find.byType(LangFoodFloatingCartPill), findsNothing);

      // Find horizontal cards and simulate add
      final horizontalCards = find.byType(LangFoodHorizontalProductCard);
      if (horizontalCards.evaluate().isNotEmpty) {
        final firstCard = tester.widget<LangFoodHorizontalProductCard>(
          horizontalCards.first,
        );
        cartProvider.addToCart(product: firstCard.product, quantity: 1);
        await tester.pump();

        // Floating pill should now appear!
        expect(find.byType(LangFoodFloatingCartPill), findsOneWidget);
        expect(find.text('1 món'), findsOneWidget);
      }
    });

    testWidgets('Search query filters products or displays Empty State', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableHomeScreen());
      await tester.pump(const Duration(milliseconds: 100));

      // Enter a non-existent search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'mon_an_khong_ton_tai_xyz_123');
      await tester.pump(const Duration(milliseconds: 100));

      // Should display empty state
      expect(find.text('Chưa tìm thấy món ngon này'), findsOneWidget);
      expect(find.text('Xem tất cả quán KTX'), findsOneWidget);

      // Tapping reset should clear query
      await tester.tap(find.text('Xem tất cả quán KTX'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Chưa tìm thấy món ngon này'), findsNothing);
    });

    final testViewports = [
      {'name': 'Compact (320x640)', 'size': const Size(320, 640)},
      {'name': 'Standard Android (360x800)', 'size': const Size(360, 800)},
      {'name': 'iPhone Standard (393x852)', 'size': const Size(393, 852)},
      {'name': 'Large Pro Max (430x932)', 'size': const Size(430, 932)},
    ];

    for (final vp in testViewports) {
      final size = vp['size'] as Size;
      final name = vp['name'] as String;

      testWidgets(
        'Responsive & Overflow Test: $name with textScale 1.0 and 1.3 without RenderFlex error',
        (WidgetTester tester) async {
          for (final scale in [1.0, 1.3]) {
            tester.view.physicalSize = Size(size.width, size.height);
            tester.view.devicePixelRatio = 1.0;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );

            await tester.pumpWidget(buildTestableHomeScreen());
            await tester.pump(const Duration(milliseconds: 150));

            // Verify no rendering or RenderFlex overflow exceptions on initial render
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'Overflow or error on $name at textScale $scale on initial render',
            );

            // Banner CTA & Content are present
            expect(find.text('Lấy mã ngay'), findsWidgets);
            expect(find.text('KHUYẾN MÃI LÀNG ĐH'), findsWidgets);

            // Bottom navigation tabs are visible
            expect(find.text('Khám phá'), findsOneWidget);
            expect(find.text('Đặt chung'), findsOneWidget);

            // Scroll down to ensure Flash Deals and product items render without overflow
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -300),
            );
            await tester.pump(const Duration(milliseconds: 100));

            expect(
              tester.takeException(),
              isNull,
              reason: 'Overflow on scroll on $name at textScale $scale',
            );

            // Flash Deals header is present and readable without overflow
            expect(find.text('Deal chớp nhoáng nghỉ trưa'), findsOneWidget);

            // Further scroll down to test bottom lists & Floating Cart area
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -400),
            );
            await tester.pump(const Duration(milliseconds: 100));

            expect(
              tester.takeException(),
              isNull,
              reason: 'Overflow on bottom scroll on $name at textScale $scale',
            );
          }
        },
      );
    }
  });
}
