import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Extension cho các semantic color tokens mở rộng mà Flutter ThemeData chưa có sẵn
class LangFoodThemeExtension extends ThemeExtension<LangFoodThemeExtension> {
  final Color canvas;
  final Color card;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color glassTint;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;

  const LangFoodThemeExtension({
    required this.canvas,
    required this.card,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.glassTint,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
  });

  static const light = LangFoodThemeExtension(
    canvas: AppColors.canvasLight,
    card: AppColors.surfaceLight,
    borderSubtle: AppColors.borderSubtleLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    glassTint: AppColors.glassLight,
    surfaceContainerLow: AppColors.surfaceContainerLowLight,
    surfaceContainerHigh: AppColors.surfaceContainerHighLight,
  );

  static const dark = LangFoodThemeExtension(
    canvas: AppColors.canvasDark,
    card: AppColors.surfaceDark,
    borderSubtle: AppColors.borderSubtleDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    glassTint: AppColors.glassDark,
    surfaceContainerLow: AppColors.surfaceContainerLowDark,
    surfaceContainerHigh: AppColors.surfaceContainerHighDark,
  );

  @override
  ThemeExtension<LangFoodThemeExtension> copyWith({
    Color? canvas,
    Color? card,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? glassTint,
    Color? surfaceContainerLow,
    Color? surfaceContainerHigh,
  }) {
    return LangFoodThemeExtension(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      glassTint: glassTint ?? this.glassTint,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
    );
  }

  @override
  ThemeExtension<LangFoodThemeExtension> lerp(
    ThemeExtension<LangFoodThemeExtension>? other,
    double t,
  ) {
    if (other is! LangFoodThemeExtension) return this;
    return LangFoodThemeExtension(
      canvas: Color.lerp(canvas, other.canvas, t) ?? canvas,
      card: Color.lerp(card, other.card, t) ?? card,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      glassTint: Color.lerp(glassTint, other.glassTint, t) ?? glassTint,
      surfaceContainerLow:
          Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t) ??
          surfaceContainerLow,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t) ??
          surfaceContainerHigh,
    );
  }
}

/// Tiện ích lấy nhanh extension qua BuildContext: context.langFoodTheme
extension LangFoodThemeContext on BuildContext {
  LangFoodThemeExtension get langFoodTheme =>
      Theme.of(this).extension<LangFoodThemeExtension>() ??
      (isDarkMode ? LangFoodThemeExtension.dark : LangFoodThemeExtension.light);
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Shared appearance for all three roles.
abstract final class AppTheme {
  static final lightTheme = _build(
    LangFoodThemeExtension.light,
    Brightness.light,
  );
  static final darkTheme = _build(LangFoodThemeExtension.dark, Brightness.dark);

  static ThemeData _build(
    LangFoodThemeExtension colors,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final actionInk = dark ? const Color(0xFFFFAA87) : AppColors.primaryDeep;
    final actionFill = dark ? const Color(0xFFFFAD8A) : AppColors.primaryDeep;
    final onAction = dark ? const Color(0xFF31140B) : Colors.white;
    final text = AppTypography.createTextTheme(colors.textPrimary);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: const Color(0xFF241007),
          primaryContainer: dark
              ? const Color(0xFF542B1E)
              : const Color(0xFFFFE5D8),
          onPrimaryContainer: actionInk,
          secondary: dark ? const Color(0xFFD1C3FF) : AppColors.campusViolet,
          onSecondary: dark ? AppColors.campusInk : Colors.white,
          secondaryContainer: dark
              ? const Color(0xFF3D2D70)
              : const Color(0xFFEDE6FF),
          onSecondaryContainer: dark
              ? const Color(0xFFE6DBFF)
              : const Color(0xFF4025AA),
          surface: colors.card,
          onSurface: colors.textPrimary,
          onSurfaceVariant: colors.textSecondary,
          surfaceContainer: colors.surfaceContainerLow,
          surfaceContainerHigh: colors.surfaceContainerHigh,
          outline: colors.borderSubtle,
          outlineVariant: colors.borderSubtle,
          surfaceTint: Colors.transparent,
        );
    const shape = RoundedSuperellipseBorder(
      borderRadius: AppTokens.borderRadiusXl,
    );
    final border = OutlineInputBorder(
      borderRadius: AppTokens.borderRadiusLg,
      borderSide: BorderSide(color: colors.borderSubtle),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: colors.canvas,
      textTheme: text,
      extensions: [colors],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _LangFoodPageTransitions(),
          TargetPlatform.iOS: _LangFoodPageTransitions(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        foregroundColor: colors.textPrimary,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape.copyWith(side: BorderSide(color: colors.borderSubtle)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusSheet,
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: colors.card, shape: shape),
      dividerTheme: DividerThemeData(color: colors.borderSubtle, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: AppTypography.bodyMd.copyWith(color: colors.textSecondary),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: actionInk, width: 1.5),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: actionFill,
          foregroundColor: onAction,
          elevation: 0,
          minimumSize: const Size(48, 50),
          shape: shape,
          textStyle: AppTypography.titleMd,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: actionFill,
          foregroundColor: onAction,
          minimumSize: const Size(48, 50),
          shape: shape,
          textStyle: AppTypography.titleMd,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: actionInk,
          side: BorderSide(color: colors.borderSubtle),
          minimumSize: const Size(48, 50),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: actionInk),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.campusInk,
        contentTextStyle: AppTypography.bodyMd.copyWith(color: Colors.white),
        actionTextColor: const Color(0xFFFFBAA0),
        shape: shape,
      ),
    );
  }
}

class _LangFoodPageTransitions extends CupertinoPageTransitionsBuilder {
  const _LangFoodPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : super.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}
