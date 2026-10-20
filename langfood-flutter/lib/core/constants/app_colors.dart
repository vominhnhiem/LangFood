import 'package:flutter/material.dart';

/// Bảng màu chuẩn của LangFood Campus Express
/// Tương thích 100% với các màn hình hiện tại và bổ sung semantic tokens của Stitch V1 (Apple HIG)
class AppColors {
  // Brand Colors (Màu nhận diện thương hiệu)
  static const Color primary = Color(0xFFFF5722); // Deep Orange (#FF5722)
  static const Color primaryDark = Color(0xFFE64A19);
  static const Color primaryDeep = Color(
    0xFFB02F00,
  ); // Stitch tone đậm (#B02F00)
  static const Color primaryLight = Color(0xFFFFCCBC);
  static const Color primaryContainer = Color(0xFFFF5722);
  static const Color onPrimary = Colors.white;
  static const Color accent = Color(0xFFFF9800); // Golden Citrus
  static const Color secondary = Color(0xFF8B5000);
  static const Color tertiary = Color(0xFF006B27); // Stitch tertiary green

  // Background & Surface - Light Mode
  static const Color background = Color(0xFFF8F9FA); // Legacy background
  static const Color canvasLight = Color(
    0xFFF2F2F7,
  ); // Apple HIG Grouped Canvas (#F2F2F7)
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;
  static const Color surfaceLight = Colors.white;
  static const Color surfaceContainerLowLight = Color(0xFFF4F3F8);
  static const Color surfaceContainerHighLight = Color(0xFFE9E7ED);

  // Background & Surface - Dark Mode
  static const Color canvasDark = Color(0xFF1C1C1E); // Apple HIG Dark Canvas
  static const Color surfaceDark = Color(0xFF2C2C2E); // Elevated Dark Card
  static const Color surfaceContainerLowDark = Color(0xFF242426);
  static const Color surfaceContainerHighDark = Color(0xFF3A3A3C);

  // Text Colors - Light Mode
  static const Color textPrimary = Color(0xFF212121);
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textHint = Color(0xFF9E9E9E);

  // Text Colors - Dark Mode
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color textHintDark = Color(0xFF636366);

  // Status & Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successApple = Color(
    0xFF34C759,
  ); // Apple HIG Success (#34C759)
  static const Color error = Color(0xFFE53935);
  static const Color errorApple = Color(0xFFBA1A1A); // Stitch error (#BA1A1A)
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF1E88E5);

  // Border & Dividers
  static const Color border = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color borderSubtleLight = Color(0xFFE5E5EA);
  static const Color borderSubtleDark = Color(0xFF38383A);

  // Translucent / Glassmorphism Materials
  static const Color glassLight = Color(
    0xD9FFFFFF,
  ); // rgba(255, 255, 255, 0.85)
  static const Color glassDark = Color(0xD12C2C2E); // rgba(44, 44, 46, 0.82)
  static const Color scrim = Color(0x73000000); // 45% black overlay
}
