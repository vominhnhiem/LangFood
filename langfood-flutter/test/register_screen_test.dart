import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langfood_flutter/data/services/auth_service.dart';
import 'package:langfood_flutter/screens/auth/register_screen.dart';

class RegistrationApi extends AuthService {
  bool failBuildings = false;
  int otpRequests = 0;

  @override
  Future<List<Map<String, dynamic>>> getBuildings() async {
    if (failBuildings) throw Exception('API unavailable');
    return [
      {'id': 42, 'name': 'Tòa từ API'},
    ];
  }

  @override
  Future<String> sendOtp(String email) async {
    otpRequests++;
    throw Exception('Email service unavailable');
  }
}

void main() {
  testWidgets('building failures show retry without sample buildings', (
    tester,
  ) async {
    final api = RegistrationApi()..failBuildings = true;
    await tester.pumpWidget(
      MaterialApp(home: RegisterScreen(authService: api)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tải được tòa nhà'), findsOneWidget);
    expect(find.text('Tòa A1'), findsNothing);
    expect(
      tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .items,
      isEmpty,
    );
    api.failBuildings = false;
    await tester.ensureVisible(find.text('Tải lại tòa nhà'));
    await tester.tap(find.text('Tải lại tòa nhà'));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButton<int>>(
      find.byType(DropdownButton<int>),
    );
    expect(dropdown.items!.single.value, 42);
    expect(dropdown.value, isNull);
  });

  testWidgets(
    'failed OTP sends never open a verification dialog or suggest a test code',
    (tester) async {
      final api = RegistrationApi();
      await tester.pumpWidget(
        MaterialApp(home: RegisterScreen(authService: api)),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      const values = [
        'Test User',
        'test_user',
        'test@example.com',
        '0901234567',
        'B402',
        'Password123',
        'Password123',
      ];
      expect(fields, findsNWidgets(values.length));
      for (var i = 0; i < values.length; i++) {
        await tester.enterText(fields.at(i), values[i]);
      }
      final submit = find.byType(ElevatedButton);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.otpRequests, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('Không gửi được OTP'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && (widget.data ?? '').contains('123456'),
        ),
        findsNothing,
      );
    },
  );
}
