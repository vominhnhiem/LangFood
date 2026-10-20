import 'package:flutter_test/flutter_test.dart';
import 'package:langfood_flutter/main.dart';

void main() {
  testWidgets('LangFoodApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LangFoodApp());

    // Verify that LangFoodApp renders
    expect(find.byType(LangFoodApp), findsOneWidget);
  });
}
