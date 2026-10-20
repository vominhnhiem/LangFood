import 'package:flutter/material.dart';

/// Các token nền tảng về khoảng cách, bán kính bo góc và đổ bóng
/// Dựa trên tiêu chuẩn 8pt spatial cadence của Stitch V1 / Apple HIG
class AppTokens {
  // Spacing (Khoảng cách theo 8pt cadence + 4pt half-steps)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  // Layout Gutters & Margins
  static const double marginMobile = 16.0;
  static const double gutterSm = 8.0;
  static const double gutterMd = 16.0;

  // Border Radius (Bán kính bo góc squircle)
  static const double radiusXs = 8.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 12.0; // Input fields, thumbnails
  static const double radiusLg = 16.0; // Cards, CTA buttons
  static const double radiusXl = 20.0;
  static const double radiusSheet = 24.0; // Bottom sheets top-corners
  static const double radiusXxl = 32.0;
  static const double radiusFull = 9999.0; // Pills, chips, steppers

  // Border Radius BorderRadius objects
  static const BorderRadius borderRadiusSm = BorderRadius.all(
    Radius.circular(radiusSm),
  );
  static const BorderRadius borderRadiusMd = BorderRadius.all(
    Radius.circular(radiusMd),
  );
  static const BorderRadius borderRadiusLg = BorderRadius.all(
    Radius.circular(radiusLg),
  );
  static const BorderRadius borderRadiusXl = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius borderRadiusSheet = BorderRadius.vertical(
    top: Radius.circular(radiusSheet),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Elevations & Shadows
  // Level 1: Resting Cards
  static const List<BoxShadow> shadowLevel1 = [
    BoxShadow(
      color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x05000000), // rgba(0, 0, 0, 0.02)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  // Level 1 Dark Mode (viền định hình bề mặt tối)
  static const List<BoxShadow> shadowLevel1Dark = [
    BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  // Level 2: Interactive Overlays / Steppers
  static const List<BoxShadow> shadowLevel2 = [
    BoxShadow(
      color: Color(0x14000000), // rgba(0, 0, 0, 0.08)
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Level 3: Bottom Sheets & Floating Cart Bars
  static const List<BoxShadow> shadowLevel3 = [
    BoxShadow(
      color: Color(0x1F000000), // rgba(0, 0, 0, 0.12)
      blurRadius: 24,
      offset: Offset(0, -6),
    ),
  ];

  // Primary Button Glow Shadow
  static const List<BoxShadow> shadowPrimaryButton = [
    BoxShadow(
      color: Color(0x40FF5722), // rgba(255, 87, 34, 0.25)
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
