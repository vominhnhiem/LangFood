import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langfood_flutter/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('RegisterScreen renders properly with all form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

    // Verify key titles and form elements
    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.text('Tạo tài khoản Làng Food'), findsOneWidget);
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
