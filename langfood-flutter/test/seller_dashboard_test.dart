import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/features/restaurant/presentation/screens/seller_dashboard_demo.dart';
import 'package:langfood_flutter/features/restaurant/presentation/screens/seller_dashboard_screen.dart';
import 'package:langfood_flutter/features/restaurant/presentation/screens/seller_dashboard_widgets.dart';

void main() {
  late DateTime now;

  Future<void> openDashboard(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    now = DateTime.utc(2026, 11, 8, 4, 30);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SellerDashboardScreen(now: () => now),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Finder card(String code) =>
      find.ancestor(of: find.text(code), matching: find.byType(OrderCardItem));

  testWidgets(
    'receiving and finishing a meal moves the same order between queues',
    (tester) async {
      await openDashboard(tester);
      final order = card('#LF-108');
      expect(
        find.descendant(of: order, matching: find.text('01:45')),
        findsOneWidget,
      );

      await tap(
        tester,
        find.descendant(of: order, matching: find.text('Nhận đơn')),
      );
      expect(
        find.descendant(
          of: find.widgetWithText(Tab, 'Đơn mới'),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      await tap(tester, find.text('Mở danh sách'));
      await tester.scrollUntilVisible(
        order,
        250,
        scrollable: find.descendant(
          of: find.byKey(const PageStorageKey(SellerQueue.cooking)),
          matching: find.byType(Scrollable),
        ),
      );
      expect(order, findsOneWidget);
      await tap(
        tester,
        find.descendant(of: order, matching: find.text('Báo xong món')),
      );
      await tap(tester, find.text('Mở danh sách'));
      expect(
        find.descendant(of: order, matching: find.text('Đang tìm shipper')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'expiry while rejecting preserves the expiry reason and history search',
    (tester) async {
      await openDashboard(tester);
      await tap(
        tester,
        find.descendant(of: card('#LF-108'), matching: find.text('Từ chối')),
      );
      now = now.add(const Duration(seconds: 106));
      await tester.pump(const Duration(seconds: 1));
      await tap(tester, find.text('Từ chối vì Hết món'));
      await tap(tester, find.widgetWithText(Tab, 'Lịch sử'));
      await tester.enterText(find.byType(TextField), '108');
      await tester.pumpAndSettle();
      expect(find.text('Hết giờ xác nhận.'), findsOneWidget);
      expect(find.text('Quán từ chối · Hết món'), findsNothing);
      expect(find.text('#LF-103'), findsNothing);
    },
  );

  testWidgets('stock and the 15-minute pause apply to future demo arrivals', (
    tester,
  ) async {
    final calls = <String>[];
    const channel = MethodChannel('langfood/seller_order_alert');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await openDashboard(tester);
    await tap(tester, find.text('Tạm ngưng 15 phút'));
    await tap(tester, find.text('Tạo đơn thử'));
    expect(calls, isNot(contains('play')));
    expect(find.text('Mở lại quán để nhận đơn thử mới.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tap(tester, find.textContaining('Hết món nhanh ·'));
    await tap(tester, find.widgetWithText(SwitchListTile, 'Cơm sườn'));
    await tap(tester, find.widgetWithText(SwitchListTile, 'Trứng ốp la'));
    await tap(tester, find.byTooltip('Đóng'));
    expect(find.text('Hết món nhanh · 3 đã tắt'), findsOneWidget);
    now = now.add(const Duration(minutes: 15));
    await tester.pump(const Duration(seconds: 1));
    await tester.drag(find.byType(NestedScrollView), const Offset(0, 500));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Tạo đơn thử'));
    expect(calls.where((method) => method == 'play'), hasLength(1));
    final order = card('#LF-110');
    expect(
      find.descendant(of: order, matching: find.text('Cơm gà xối mỡ')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: order, matching: find.textContaining('Trứng ốp la')),
      findsNothing,
    );
  });

  testWidgets(
    'all four order queues and stock are reachable on a narrow phone',
    (tester) async {
      await openDashboard(
        tester,
        width: 320,
        textScale: 1.65,
        themeMode: ThemeMode.dark,
      );
      await tester.drag(find.byType(NestedScrollView), const Offset(0, -420));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(TabBar));
      expect(find.byType(Tab), findsNWidgets(4));
      for (var index = 0; index < 4; index++) {
        final tab = tester.getRect(find.byType(Tab).at(index));
        expect(tab.left, greaterThanOrEqualTo(bar.left));
        expect(tab.right, lessThanOrEqualTo(bar.right));
      }
      await tap(tester, find.widgetWithText(Tab, 'Lịch sử'));
      expect(find.byType(TextField), findsOneWidget);
      await tap(tester, find.textContaining('Hết món nhanh ·'));
      expect(find.byType(QuickStockSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
