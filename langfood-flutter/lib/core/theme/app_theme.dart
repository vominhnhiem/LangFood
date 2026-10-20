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
      LangFoodThemeExtension.light;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Hệ thống Theme chính thức của LangFood Campus Express
class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    final textTheme = AppTypography.createTextTheme(AppColors.textPrimaryLight);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.canvasLight,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDeep,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.surfaceContainerLowLight,
        onSecondaryContainer: AppColors.textPrimaryLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.errorApple,
        onError: Colors.white,
        outline: AppColors.borderSubtleLight,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: AppTypography.titleMd.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusLg,
          side: BorderSide(color: AppColors.borderSubtleLight, width: 0.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusSheet,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        border: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderSubtleLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderSubtleLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.errorApple),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusLg),
          textStyle: AppTypography.titleMd.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusLg),
          textStyle: AppTypography.titleMd.copyWith(color: AppColors.primary),
        ),
      ),
      extensions: const [LangFoodThemeExtension.light],
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final textTheme = AppTypography.createTextTheme(AppColors.textPrimaryDark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.canvasDark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.surfaceContainerHighDark,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.surfaceContainerLowDark,
        onSecondaryContainer: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.errorApple,
        onError: Colors.white,
        outline: AppColors.borderSubtleDark,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: AppTypography.titleMd.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusLg,
          side: BorderSide(color: AppColors.borderSubtleDark, width: 0.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.borderRadiusSheet,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        border: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderSubtleDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.borderSubtleDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTokens.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.errorApple),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusLg),
          textStyle: AppTypography.titleMd.copyWith(color: Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.borderRadiusLg),
          textStyle: AppTypography.titleMd.copyWith(color: AppColors.primary),
        ),
      ),
      extensions: const [LangFoodThemeExtension.dark],
    );
  }
}
