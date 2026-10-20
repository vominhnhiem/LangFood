import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/data/models/product_model.dart';
import 'package:langfood_flutter/data/models/product_option_model.dart';
import 'package:langfood_flutter/data/models/shop_model.dart';
import 'package:langfood_flutter/features/food_detail/presentation/widgets/food_customization_sheet.dart';
import 'package:langfood_flutter/features/shop/presentation/screens/shop_menu_screen.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:langfood_flutter/providers/cart_provider.dart';
import 'package:langfood_flutter/providers/theme_provider.dart';

void main() {
  group('UI-04 FoodCustomizationSheet Tests (LF-03 Medium & LF-04 Expanded Stitch)', () {
    // Fixture: Món ăn chuẩn có đầy đủ nhóm tùy chọn (Size, Sốt, Toppings)
    final mockProductWithOptions = ProductModel(
      id: 101,
      name: 'Cơm Gà Xối Mỡ Da Giòn',
      description: 'Đùi gà góc tư chiên giòn, cơm chiên hoàng kim kèm canh',
      price: 35000,
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
      shopId: 1,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryName: 'Cơm gà',
      isShopOpen: true,
      optionGroups: [
        // Nhóm 1: Chọn size (Chọn 1 / Single select)
        ProductOptionGroupModel(
          id: 1,
          productId: 101,
          name: 'Chọn Size phần ăn',
          isMultiple: false,
          options: [
            ProductOptionModel(
              id: 11,
              groupId: 1,
              name: 'Nhỏ (Vừa bụng)',
              price: 0,
              isSelected: true,
            ),
            ProductOptionModel(
              id: 12,
              groupId: 1,
              name: 'Tiêu Chuẩn',
              price: 10000,
              isSelected: false,
            ),
            ProductOptionModel(
              id: 13,
              groupId: 1,
              name: 'Khổng Lồ (2 Đùi)',
              price: 25000,
              isSelected: false,
            ),
          ],
        ),
        // Nhóm 2: Sốt mắm tỏi & Vị cay (Chọn 1 / Single select)
        ProductOptionGroupModel(
          id: 2,
          productId: 101,
          name: 'Sốt mắm tỏi & Vị cay',
          isMultiple: false,
          options: [
            ProductOptionModel(
              id: 21,
              groupId: 2,
              name: 'Vừa cay ớt xiêm',
              price: 0,
              isSelected: true,
            ),
            ProductOptionModel(
              id: 22,
              groupId: 2,
              name: 'Cay xé lưỡi',
              price: 0,
              isSelected: false,
            ),
            ProductOptionModel(
              id: 23,
              groupId: 2,
              name: 'Không cay',
              price: 0,
              isSelected: false,
            ),
          ],
        ),
        // Nhóm 3: Topping & Món kèm (Chọn nhiều / Multi select)
        ProductOptionGroupModel(
          id: 3,
          productId: 101,
          name: 'Topping & Món ăn kèm',
          isMultiple: true,
          options: [
            ProductOptionModel(
              id: 31,
              groupId: 3,
              name: 'Trứng ốp la lòng đào',
              price: 5000,
              isSelected: false,
            ),
            ProductOptionModel(
              id: 32,
              groupId: 3,
              name: 'Canh rong biển thịt bằm',
              price: 7000,
              isSelected: false,
            ),
            ProductOptionModel(
              id: 33,
              groupId: 3,
              name: 'Cơm chiên hoàng kim thêm',
              price: 6000,
              isSelected: false,
            ),
          ],
        ),
      ],
    );

    // Fixture: Món ăn không có option
    final mockProductWithoutOptions = ProductModel(
      id: 102,
      name: 'Trà Tắc Xí Muội Khổng Lồ',
      description: 'Ly 700ml chua ngọt giải nhiệt KTX',
      price: 15000,
      shopId: 1,
      shopName: 'Cơm Gà Xối Mỡ Bà Tám',
      categoryName: 'Nước uống',
      isShopOpen: true,
      optionGroups: const [],
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

    Widget buildTestableCustomizationSheet({
      required ProductModel product,
      CartProvider? cartProvider,
      AuthProvider? authProvider,
      ThemeProvider? themeProvider,
      ThemeMode themeMode = ThemeMode.light,
      double textScaleFactor = 1.0,
      VoidCallback? onCartAdded,
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      FoodCustomizationSheet.show(
                        context: context,
                        product: product,
                        onCartAdded: onCartAdded,
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    testWidgets(
      '1. Medium Sheet (LF-03) renders key elements: thumbnail, dish name, base price, size options, stepper, sticky CTA',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(product: mockProductWithOptions),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Kiểm tra tiêu đề món ăn & nhãn
        expect(find.text('Cơm Gà Xối Mỡ Da Giòn'), findsOneWidget);
        expect(find.text('Cơm gà'), findsOneWidget);
        expect(find.text('KTX Top 1'), findsOneWidget);
        expect(
          find.text('35.000₫'),
          findsWidgets,
        ); // Giá cơ bản và giá tổng ban đầu

        // Kiểm tra nhóm Size (Bắt buộc)
        expect(find.text('1. Chọn Size phần ăn'), findsOneWidget);
        expect(find.text('Nhỏ (Vừa bụng)'), findsOneWidget);
        expect(find.text('Tiêu Chuẩn'), findsOneWidget);
        expect(find.text('Khổng Lồ (2 Đùi)'), findsOneWidget);

        // Kiểm tra bộ đếm số lượng (Stepper) ban đầu = 1
        expect(find.text('1'), findsOneWidget);
        expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
        expect(find.byIcon(Icons.add_rounded), findsOneWidget);

        // Kiểm tra nút Sticky CTA
        expect(find.text('Thêm vào giỏ'), findsOneWidget);
        expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      },
    );

    testWidgets(
      '2. Expanded Sheet (LF-04) renders all option sections, notes, quick chips, and campus pill',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(product: mockProductWithOptions),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Kéo mở rộng sheet lên cao
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        // Kiểm tra Nhóm 2: Sốt mắm tỏi & Vị cay
        expect(find.text('2. Sốt mắm tỏi & Vị cay'), findsOneWidget);
        expect(find.text('Vừa cay ớt xiêm'), findsOneWidget);

        // Kiểm tra Nhóm 3: Topping & Món kèm
        expect(find.text('3. Topping & Món ăn kèm'), findsOneWidget);
        expect(find.text('Trứng ốp la lòng đào'), findsOneWidget);
        expect(find.text('Canh rong biển thịt bằm'), findsOneWidget);

        // Kiểm tra Ghi chú cho quán & Quick chips
        expect(find.text('Lời nhắn cho bếp'), findsOneWidget);
        expect(find.text('+ Ít cay'), findsOneWidget);
        expect(find.text('+ Da gà thật giòn'), findsOneWidget);
        expect(find.text('+ Giao sảnh KTX'), findsOneWidget);

        // Kiểm tra banner bảo chứng KTX
        expect(find.byIcon(Icons.electric_moped_rounded), findsOneWidget);
        expect(
          find.textContaining('Shipper sinh viên giao tận cửa phòng KTX'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3. Radio group (single select) updates selection exclusively and recalculates total price',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(product: mockProductWithOptions),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Ban đầu: Size 'Nhỏ' (+0₫) -> Giá tổng = 35.000₫
        expect(find.text('35.000₫'), findsWidgets);

        // Chọn size 'Tiêu Chuẩn' (+10.000₫)
        await tester.tap(find.text('Tiêu Chuẩn'));
        await tester.pumpAndSettle();

        // Giá tổng mới = 35.000₫ + 10.000₫ = 45.000₫
        expect(find.text('45.000₫'), findsOneWidget);

        // Chọn tiếp size 'Khổng Lồ (2 Đùi)' (+25.000₫)
        await tester.tap(find.text('Khổng Lồ (2 Đùi)'));
        await tester.pumpAndSettle();

        // Giá tổng mới = 35.000₫ + 25.000₫ = 60.000₫ (loại trừ giá của 'Tiêu Chuẩn')
        expect(find.text('60.000₫'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Checkbox group (multi select) toggles add-ons and updates total price dynamically',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(product: mockProductWithOptions),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Cuộn tới nhóm topping
        await tester.scrollUntilVisible(
          find.text('Trứng ốp la lòng đào'),
          50,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        // Ban đầu = 35.000₫
        // Chọn Topping 1: Trứng ốp la (+5.000₫)
        await tester.tap(find.text('Trứng ốp la lòng đào'));
        await tester.pumpAndSettle();
        expect(find.text('40.000₫'), findsOneWidget);

        // Chọn tiếp Topping 2: Canh rong biển (+7.000₫)
        await tester.tap(find.text('Canh rong biển thịt bằm'));
        await tester.pumpAndSettle();
        expect(find.text('47.000₫'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Deselecting a checkbox option decreases total price accurately',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(product: mockProductWithOptions),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Trứng ốp la lòng đào'),
          50,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        // Chọn Trứng ốp la (+5.000₫) -> 40.000₫
        await tester.tap(find.text('Trứng ốp la lòng đào'));
        await tester.pumpAndSettle();
        expect(find.text('40.000₫'), findsOneWidget);

        // Bỏ chọn Trứng ốp la -> Quay về 35.000₫
        await tester.tap(find.text('Trứng ốp la lòng đào'));
        await tester.pumpAndSettle();
        expect(find.text('35.000₫'), findsWidgets);
      },
    );

    testWidgets(
      '6. Quantity stepper increment and decrement multiplies total price accurately',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(product: mockProductWithOptions),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Chọn size Tiêu Chuẩn (+10.000₫) -> Đơn giá = 45.000₫
        await tester.tap(find.text('Tiêu Chuẩn'));
        await tester.pumpAndSettle();
        expect(find.text('45.000₫'), findsOneWidget);

        // Tăng số lượng lên 2
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        expect(find.text('2'), findsOneWidget);
        // Tổng giá = 45.000₫ * 2 = 90.000₫
        expect(find.text('90.000₫'), findsOneWidget);

        // Tăng tiếp lên 3
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(find.text('3'), findsOneWidget);
        expect(find.text('135.000₫'), findsOneWidget);

        // Giảm lại xuống 2
        await tester.tap(find.byIcon(Icons.remove_rounded));
        await tester.pumpAndSettle();
        expect(find.text('2'), findsOneWidget);
        expect(find.text('90.000₫'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Quick note chips append text to note field, clear button resets note',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(product: mockProductWithOptions),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('+ Ít cay'),
          50,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        // Nhấn chip '+ Ít cay'
        await tester.tap(find.text('+ Ít cay'));
        await tester.pumpAndSettle();
        expect(find.text('Ít cay'), findsOneWidget);

        // Nhấn tiếp chip '+ Mắm riêng'
        await tester.tap(find.text('+ Mắm riêng'));
        await tester.pumpAndSettle();
        expect(find.text('Ít cay, Mắm riêng'), findsOneWidget);

        // Cuộn để nút xóa hiển thị hoàn toàn
        await tester.scrollUntilVisible(
          find.byIcon(Icons.cancel_rounded),
          50,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        // Nhấn nút xóa 'cancel_rounded'
        await tester.tap(find.byIcon(Icons.cancel_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Ít cay, Mắm riêng'), findsNothing);
      },
    );

    testWidgets(
      '8. Adding to cart calls CartProvider.addToCart with correct data and closes sheet',
      (tester) async {
        setMobileViewport(tester);
        final cartProvider = CartProvider();
        bool callbackCalled = false;

        await tester.pumpWidget(
          buildTestableCustomizationSheet(
            product: mockProductWithOptions,
            cartProvider: cartProvider,
            onCartAdded: () => callbackCalled = true,
          ),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Tăng số lượng lên 2
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();

        // Nhấn nút Thêm vào giỏ
        await tester.tap(find.text('Thêm vào giỏ'));
        await tester.pumpAndSettle();

        // Kiểm tra giỏ hàng có 1 loại món với quantity = 2
        expect(cartProvider.items.length, 1);
        expect(cartProvider.items.first.quantity, 2);
        expect(cartProvider.items.first.product.id, 101);
        expect(
          cartProvider.items.first.selectedOptionsJson,
          contains('Nhỏ (Vừa bụng)'),
        );
        expect(callbackCalled, isTrue);

        // Sheet đã đóng lại
        expect(find.text('Lời nhắn cho bếp'), findsNothing);
      },
    );

    testWidgets(
      '9. Product with empty option groups renders clean standard layout without fake options',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(product: mockProductWithoutOptions),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Trà Tắc Xí Muội Khổng Lồ'), findsOneWidget);
        expect(find.text('Công thức chuẩn vị quán'), findsOneWidget);
        expect(find.text('15.000₫'), findsWidgets);

        // Không hiển thị các nhóm size/topping giả
        expect(find.text('1. Chọn Size phần ăn'), findsNothing);
        expect(find.text('3. Topping & Món ăn kèm'), findsNothing);
      },
    );

    testWidgets(
      '10. Responsive layout testing across viewports (320, 360, 393, 430 logical px)',
      (tester) async {
        final viewports = [
          const Size(320 * 2.0, 640 * 2.0),
          const Size(360 * 2.0, 800 * 2.0),
          const Size(393 * 2.0, 852 * 2.0),
          const Size(430 * 2.0, 932 * 2.0),
        ];

        for (final size in viewports) {
          setMobileViewport(tester, size);
          await tester.pumpWidget(
            buildTestableCustomizationSheet(product: mockProductWithOptions),
          );
          await tester.tap(find.text('Open Sheet'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Thêm vào giỏ'), findsOneWidget);

          // Đóng sheet
          await tester.tap(find.byIcon(Icons.close_rounded));
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      '11. Text scaling (1.3x) layout safety test without RenderFlex overflow',
      (tester) async {
        setMobileViewport(tester);
        await tester.pumpWidget(
          buildTestableCustomizationSheet(
            product: mockProductWithOptions,
            textScaleFactor: 1.3,
          ),
        );
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Cơm Gà Xối Mỡ Da Giòn'), findsOneWidget);
        expect(find.text('Thêm vào giỏ'), findsOneWidget);
      },
    );

    testWidgets('12. Dark Mode renders cleanly with correct theme tokens', (
      tester,
    ) async {
      setMobileViewport(tester);
      await tester.pumpWidget(
        buildTestableCustomizationSheet(
          product: mockProductWithOptions,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Cơm Gà Xối Mỡ Da Giòn'), findsOneWidget);
      expect(find.text('Thêm vào giỏ'), findsOneWidget);
    });

    testWidgets(
      '13. Tapping "Tùy chọn" in ShopMenuScreen opens FoodCustomizationSheet',
      (tester) async {
        setMobileViewport(tester, const Size(1080, 2400));
        final mockShop = ShopModel(
          id: 1,
          name: 'Cơm Gà Xối Mỡ Bà Tám',
          address: 'Cổng sau ĐH Khoa Học Tự Nhiên, KTX Khu B',
          isOpen: true,
        );

        final cartProvider = CartProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
              ChangeNotifierProvider<AuthProvider>(
                create: (_) => AuthProvider(),
              ),
              ChangeNotifierProvider<ThemeProvider>(
                create: (_) => ThemeProvider(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: ShopMenuScreen(
                shopId: 1,
                initialShop: mockShop,
                initialProducts: [mockProductWithOptions],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Cuộn để nút "Tùy chọn" hiển thị hoàn toàn trên màn hình
        await tester.scrollUntilVisible(
          find.text('Tùy chọn'),
          50,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Chạm vào nút "Tùy chọn"
        await tester.tap(find.text('Tùy chọn'));
        await tester.pumpAndSettle();

        // Xác minh FoodCustomizationSheet mở thành công
        expect(find.byType(FoodCustomizationSheet), findsOneWidget);
        expect(find.text('1. Chọn Size phần ăn'), findsOneWidget);
        expect(find.text('Thêm vào giỏ'), findsOneWidget);
      },
    );
  });
}
