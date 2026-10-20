import 'dart:ui';

import 'package:flutter/material.dart';

/// Hệ thống Typography chuẩn Stitch V1 / Apple HIG cho LangFood
/// Tuân thủ nghiêm ngặt line-height >= 120-130% để không bị cắt dấu tiếng Việt
/// và hỗ trợ số dạng Tabular Figures cho tiền tệ / số lượng
class AppTypography {
  static const List<String> _fontFallbacks = [
    'Inter',
    'SF Pro Text',
    'SF Pro Display',
    'San Francisco',
    'Roboto',
    'Arial',
  ];

  // Headline Scales
  static const TextStyle headlineXl = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 41 / 34, // ~1.21
    letterSpacing: -0.68,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28, // ~1.21
    letterSpacing: -0.42,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22, // ~1.27
    letterSpacing: -0.22,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 25 / 20, // 1.25
    letterSpacing: -0.10,
  );

  // Title Scales
  static const TextStyle titleMd = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 22 / 17, // ~1.29
    letterSpacing: -0.08,
  );

  // Body Scales
  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 22 / 17, // ~1.29
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 20 / 15, // ~1.33
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13, // ~1.38
  );

  // Label Scales
  static const TextStyle labelLg = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15, // ~1.33
  );

  static const TextStyle labelMd = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13, // ~1.38
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 14 / 11, // ~1.27
    letterSpacing: 0.11,
  );

  // Currency & Counter Display (bắt buộc Tabular Figures)
  static const TextStyle currencyDisplay = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 22 / 18,
    letterSpacing: -0.18,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle counterDisplay = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: _fontFallbacks,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 18 / 15,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// Tạo TextTheme chuẩn cho Material 3
  static TextTheme createTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: headlineXl.copyWith(color: textColor),
      displayMedium: headlineLg.copyWith(color: textColor),
      displaySmall: headlineMd.copyWith(color: textColor),
      headlineLarge: headlineLg.copyWith(color: textColor),
      headlineMedium: headlineMd.copyWith(color: textColor),
      headlineSmall: headlineSm.copyWith(color: textColor),
      titleLarge: headlineSm.copyWith(color: textColor),
      titleMedium: titleMd.copyWith(color: textColor),
      titleSmall: labelLg.copyWith(color: textColor),
      bodyLarge: bodyLg.copyWith(color: textColor),
      bodyMedium: bodyMd.copyWith(color: textColor),
      bodySmall: bodySm.copyWith(color: textColor),
      labelLarge: labelLg.copyWith(color: textColor),
      labelMedium: labelMd.copyWith(color: textColor),
      labelSmall: labelSm.copyWith(color: textColor),
    );
  }
}
