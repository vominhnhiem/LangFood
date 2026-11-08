import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/langfood_campus_route.dart';

/// A short brand reveal on entry to the authentication screen.
class AuthIntro extends StatefulWidget {
  const AuthIntro({super.key, required this.child});

  final Widget child;

  @override
  State<AuthIntro> createState() => _AuthIntroState();
}

class _AuthIntroState extends State<AuthIntro>
    with SingleTickerProviderStateMixin {
  late final _timeline = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final Animation<double> _entrance = _timeline.drive(
    CurveTween(curve: const Interval(0, .32, curve: Curves.easeOutCubic)),
  );
  late final Animation<double> _exit = _timeline.drive(
    CurveTween(curve: const Interval(.65, 1, curve: Curves.easeInOutCubic)),
  );
  late final _logoScale = _entrance.drive(Tween(begin: .84, end: 1.0));
  late final _logoOpacity = ReverseAnimation(_exit);
  late final _logoLift = _exit.drive(
    Tween(begin: Offset.zero, end: const Offset(0, -.14)),
  );
  late final _formSlide = _exit.drive(
    Tween(begin: const Offset(0, .025), end: Offset.zero),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _skip();
    } else if (_timeline.isDismissed) {
      _timeline.forward();
    }
  }

  void _skip() => _timeline.value = 1;

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _timeline,
    child: SlideTransition(position: _formSlide, child: widget.child),
    builder: (context, child) {
      final showing = !_timeline.isCompleted;
      return Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: showing,
            child: ExcludeSemantics(excluding: showing, child: child),
          ),
          if (showing)
            FadeTransition(
              opacity: _logoOpacity,
              child: Semantics(
                button: true,
                label: 'Bỏ qua phần giới thiệu',
                onTap: _skip,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: _skip,
                  child: Material(
                    color: AppColors.campusInk,
                    child: SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: SlideTransition(
                            position: _logoLift,
                            child: FadeTransition(
                              opacity: _entrance,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: const _IntroMark(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _IntroMark extends StatelessWidget {
  const _IntroMark();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox.square(
        dimension: 88,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: AppColors.campusViolet,
            shape: RoundedSuperellipseBorder(
              borderRadius: AppTokens.borderRadiusXl,
              side: BorderSide(color: Color(0xFF876AF4)),
            ),
          ),
          child: Center(child: LangFoodCampusRoute()),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        AppConstants.appName,
        textAlign: TextAlign.center,
        style: AppTypography.headlineXl.copyWith(color: Colors.white),
      ),
      const SizedBox(height: 6),
      Text(
        'KTX KHU B',
        textAlign: TextAlign.center,
        style: AppTypography.labelSm.copyWith(
          color: AppColors.campusLime,
          letterSpacing: 2.5,
        ),
      ),
    ],
  );
}
