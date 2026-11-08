import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:langfood_flutter/features/auth/presentation/screens/register_screen.dart';
import 'package:langfood_flutter/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('login intro gives way to the interactive form', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(restoreSession: false),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));

    final intro = find.text('Làng Food');
    expect(intro, findsOneWidget);
    expect(find.text('Đăng ký').hitTestable(), findsNothing);

    await tester.pumpAndSettle();
    expect(intro, findsNothing);
    expect(find.text('Đăng ký').hitTestable(), findsOneWidget);
  });

  testWidgets('auth tabs work on a compact screen with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.65;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(restoreSession: false),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Làng Food'), findsNothing);
    expect(tester.takeException(), isNull);
    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Mừng bạn trở lại!'),
      160,
      scrollable: scroll,
    );
    final username = find.byType(EditableText).first;
    await tester.ensureVisible(username);
    await tester.pumpAndSettle();
    await tester.enterText(username, 'sinhvien');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Gia nhập Làng nhé!'),
      160,
      scrollable: scroll,
    );
    await tester.ensureVisible(find.text('Chủ quán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chủ quán'));
    await tester.pumpAndSettle();
    expect(find.text('Tên quán ăn *'), findsOneWidget);
    await tester.ensureVisible(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('sinhvien'),
      160,
      scrollable: scroll,
    );
    expect(find.text('sinhvien'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RegisterScreen renders properly with all form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    // Verify key titles and form elements
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Gia nhập Làng nhé!'), findsOneWidget);
    expect(find.text('TIẾP TỤC & XÁC THỰC OTP'), findsOneWidget);
    expect(find.text('Họ và tên *'), findsOneWidget);
    expect(find.text('Tên đăng nhập *'), findsOneWidget);
    expect(find.text('Email *'), findsOneWidget);
    expect(find.text('Số điện thoại *'), findsOneWidget);

    // Verify 3 role selector options
    expect(find.text('Bạn đăng ký với vai trò *'), findsOneWidget);
    expect(find.text('Sinh viên'), findsOneWidget);
    expect(find.text('Chủ quán'), findsOneWidget);
    expect(find.text('Shipper'), findsOneWidget);

    // Default is Sinh viên -> shows room field
    expect(find.text('Phòng'), findsOneWidget);
    expect(find.text('Tên quán ăn *'), findsNothing);
    expect(find.text('Mã số sinh viên (MSSV) *'), findsNothing);

    // Switch to Chủ quán
    await tester.tap(find.text('Chủ quán'));
    await tester.pumpAndSettle();

    expect(find.text('Họ và tên chủ quán *'), findsOneWidget);
    expect(find.text('Tên quán ăn *'), findsOneWidget);
    expect(find.text('Địa chỉ / Vị trí quán *'), findsOneWidget);
    expect(find.text('Phòng'), findsNothing);

    // Switch to Shipper
    await tester.tap(find.text('Shipper'));
    await tester.pumpAndSettle();

    expect(find.text('Họ và tên tài xế *'), findsOneWidget);
    expect(find.text('Mã số sinh viên (MSSV) *'), findsOneWidget);
    expect(find.text('Tòa nhà KTX đang lưu trú'), findsOneWidget);
    expect(find.text('Tên quán ăn *'), findsNothing);

    // Switch back to Sinh viên
    await tester.tap(find.text('Sinh viên'));
    await tester.pumpAndSettle();

    expect(find.text('Họ và tên *'), findsOneWidget);
    expect(find.text('Phòng'), findsOneWidget);
    expect(find.text('Mã số sinh viên (MSSV) *'), findsNothing);
  });
}
