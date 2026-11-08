import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_typography.dart';

/// Campus Pop's route mark, drawn without an image or animation dependency.
class LangFoodCampusRoute extends StatelessWidget {
  const LangFoodCampusRoute({super.key, this.color = AppColors.campusLime});

  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 70,
      height: 45,
      child: CustomPaint(painter: _CampusRoutePainter(color)),
    ),
  );
}

class _CampusRoutePainter extends CustomPainter {
  const _CampusRoutePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * .12, size.height * .76);
    final end = Offset(size.width * .86, size.height * .24);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width * .64,
        start.dy,
        size.width * .32,
        end.dy,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(start, 4, paint);
    canvas.drawCircle(end, 5, paint);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawCircle(end, 9, paint);
  }

  @override
  bool shouldRepaint(_CampusRoutePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A station-style label and the shared route mark. Content can grow vertically
/// with the system font size.
class LangFoodCampusBanner extends StatelessWidget {
  const LangFoodCampusBanner({
    super.key,
    required this.label,
    required this.title,
    this.detail,
  });

  final String label;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const ShapeDecoration(
      color: AppColors.campusViolet,
      shape: RoundedSuperellipseBorder(borderRadius: AppTokens.borderRadiusXl),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.campusLime,
                    borderRadius: AppTokens.borderRadiusSm,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      label,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.campusInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const LangFoodCampusRoute(),
            ],
          ),
          Text(
            title,
            style: AppTypography.headlineLg.copyWith(color: Colors.white),
          ),
          if (detail case final String description) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTypography.bodyMd.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    ),
  );
}
