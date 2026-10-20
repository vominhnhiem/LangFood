import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langfood_flutter/core/constants/app_colors.dart';
import 'package:langfood_flutter/core/showcase/design_system_showcase.dart';
import 'package:langfood_flutter/core/theme/app_theme.dart';
import 'package:langfood_flutter/core/theme/app_tokens.dart';
import 'package:langfood_flutter/core/theme/app_typography.dart';
import 'package:langfood_flutter/core/widgets/langfood_buttons.dart';
import 'package:langfood_flutter/core/widgets/langfood_card.dart';
import 'package:langfood_flutter/core/widgets/langfood_category_chip.dart';
import 'package:langfood_flutter/core/widgets/langfood_empty_state.dart';
import 'package:langfood_flutter/core/widgets/langfood_floating_cart_pill.dart';
import 'package:langfood_flutter/core/widgets/langfood_loading_skeleton.dart';
import 'package:langfood_flutter/core/widgets/langfood_quantity_stepper.dart';
import 'package:langfood_flutter/core/widgets/langfood_search_field.dart';
import 'package:langfood_flutter/core/widgets/langfood_section_header.dart';
import 'package:langfood_flutter/core/widgets/langfood_status_badge.dart';

void main() {
  group('UI-01 Design System & Theme Tests', () {
    test('Tokens and Colors validation', () {
      expect(AppColors.primary, const Color(0xFFFF5722));
      expect(AppColors.primaryDeep, const Color(0xFFB02F00));
      expect(AppTokens.spaceMd, 16.0);
      expect(AppTokens.radiusLg, 16.0);
      expect(AppTokens.radiusFull, 9999.0);
      expect(AppTypography.headlineXl.fontSize, 34);
    });

    testWidgets('Light and Dark AppTheme produce valid ColorSchemes', (
      tester,
    ) async {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.colorScheme.primary, AppColors.primary);
      expect(dark.colorScheme.primary, AppColors.primary);
    });

    testWidgets(
      'LangFoodPrimaryButton & LangFoodSecondaryButton render and respond',
      (tester) async {
        bool tappedPrimary = false;
        bool tappedSecondary = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Column(
                children: [
                  LangFoodPrimaryButton(
                    text: 'Primary CTA',
                    onPressed: () => tappedPrimary = true,
                  ),
                  LangFoodSecondaryButton(
                    text: 'Secondary CTA',
                    onPressed: () => tappedSecondary = true,
                  ),
                  const LangFoodPrimaryButton(
                    text: 'Loading CTA',
                    isLoading: true,
                    onPressed: null,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Primary CTA'), findsOneWidget);
        expect(find.text('Secondary CTA'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.text('Primary CTA'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tappedPrimary, true);

        await tester.tap(find.text('Secondary CTA'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tappedSecondary, true);
      },
    );

    testWidgets(
      'LangFoodQuantityStepper increments, decrements and triggers delete',
      (tester) async {
        int count = 2;
        bool deleted = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => LangFoodQuantityStepper(
                  value: count,
                  onChanged: (v) => setState(() => count = v),
                  onDelete: () => deleted = true,
                ),
              ),
            ),
          ),
        );

        expect(find.text('2'), findsOneWidget);

        // Tap + button
        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(count, 3);
        expect(find.text('3'), findsOneWidget);

        // Tap - button twice
        await tester.tap(find.byIcon(Icons.remove_rounded));
        await tester.pumpAndSettle();
        expect(count, 2);

        await tester.tap(find.byIcon(Icons.remove_rounded));
        await tester.pumpAndSettle();
        expect(count, 1);

        // When value is 1, the icon should be delete
        expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

        // Tap delete button
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();
        expect(deleted, true);
      },
    );

    testWidgets(
      'LangFoodFloatingCartPill renders item count and formatted price',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: LangFoodFloatingCartPill(
                totalItemCount: 3,
                totalPrice: 105000,
                label: 'Cơm Gà Bà Tám',
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text('3 món'), findsOneWidget);
        expect(find.text('Cơm Gà Bà Tám'), findsOneWidget);
        expect(find.textContaining('105.000'), findsOneWidget);
      },
    );

    testWidgets('DesignSystemShowcase renders all sections without error', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: DesignSystemShowcase()));

      expect(find.text('Design System Showcase'), findsOneWidget);
      expect(find.text('1. PALETTE & BRAND TOKENS'), findsOneWidget);
      expect(find.text('2. TYPOGRAPHY SCALE'), findsOneWidget);
      expect(find.text('3. BUTTONS (PRIMARY & SECONDARY)'), findsOneWidget);
      expect(find.text('4. SEARCH FIELD'), findsOneWidget);
      expect(find.text('5. CATEGORY CHIPS (CAPSULE PILL)'), findsOneWidget);
      expect(
        find.text('6. QUANTITY STEPPER (TABULAR FIGURES)'),
        findsOneWidget,
      );
      expect(find.text('7. STATUS BADGES & PROMOTION PILLS'), findsOneWidget);
      expect(find.text('8. CARDS & ELEVATION'), findsOneWidget);
      expect(find.text('9. LOADING SKELETONS (SHIMMER)'), findsOneWidget);
      expect(find.text('10. MODAL BOTTOM SHEET'), findsOneWidget);
      expect(find.text('11. EMPTY STATE VIEW'), findsOneWidget);
      expect(
        find.text('12. FLOATING CART PILL (STICKY LEVEL 3)'),
        findsOneWidget,
      );
    });
  });
}
