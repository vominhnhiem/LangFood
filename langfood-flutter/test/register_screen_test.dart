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
  });
}
