import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_motion.dart';
import '../../../../core/widgets/langfood_campus_route.dart';

class AuthLanding extends StatelessWidget {
  const AuthLanding({
    super.key,
    required this.form,
    this.tabs,
    this.controller,
  });

  final Widget form;
  final Widget? tabs;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final surface = context.langFoodTheme.card;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.campusInk,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: CustomScrollView(
                controller: controller,
                slivers: [
                  const SliverToBoxAdapter(child: _CampusWelcome()),
                  SliverToBoxAdapter(
                    child: Material(
                      color: surface,
                      shape: const RoundedSuperellipseBorder(
                        borderRadius: AppTokens.borderRadiusSheet,
                      ),
                      child: SafeArea(
                        top: false,
                        minimum: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (tabs case final Widget control) ...[
                              control,
                              const SizedBox(height: 20),
                            ],
                            form,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ColoredBox(color: surface),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthFormHeading extends StatelessWidget {
  const AuthFormHeading({
    super.key,
    required this.kicker,
    required this.title,
    required this.accent,
    required this.description,
  });

  final String kicker;
  final String title;
  final String accent;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.langFoodTheme;
    final violet = Theme.of(context).colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.campusInk,
                borderRadius: AppTokens.borderRadiusSm,
              ),
              child: SizedBox(
                width: 29,
                height: 20,
                child: FittedBox(child: LangFoodCampusRoute()),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                kicker,
                style: AppTypography.labelSm.copyWith(
                  color: violet,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              text: title,
              children: [
                TextSpan(
                  text: ' $accent',
                  style: TextStyle(color: violet, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            style: AppTypography.headlineLg.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTypography.bodyMd.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _CampusWelcome extends StatelessWidget {
  const _CampusWelcome();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'LÀNG FOOD / KTX KHU B',
                  style: TextStyle(
                    color: AppColors.campusLime,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppMotion.durationOf(
                  context,
                  AppMotion.durationSheet,
                ),
                curve: AppMotion.curveDefault,
                builder: (context, value, child) => Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: ClipRect(clipper: _RouteReveal(value), child: child),
                ),
                child: const LangFoodCampusRoute(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Hôm nay, ghé Làng.',
            style: AppTypography.headlineXl.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Món ngon quanh KTX, giao đến tòa bạn.',
            style: AppTypography.bodyMd.copyWith(
              color: const Color(0xFFE2D8F5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteReveal extends CustomClipper<Rect> {
  const _RouteReveal(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_RouteReveal oldClipper) => oldClipper.progress != progress;
}
