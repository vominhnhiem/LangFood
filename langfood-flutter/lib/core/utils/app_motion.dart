import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Motion, Animation and Haptic feedback utilities
class AppMotion {
  // Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSheet = Duration(milliseconds: 350);

  // Curves
  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveInOut = Curves.easeInOutCubic;
  static const Curve curveSpring = Curves.easeOutBack;

  static Duration durationOf(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  static AnimationStyle sheetStyle(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: durationSheet,
          reverseDuration: durationNormal,
        );
}

class LangFoodScrollBehavior extends MaterialScrollBehavior {
  const LangFoodScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      switch (getPlatform(context)) {
        TargetPlatform.android || TargetPlatform.iOS =>
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        _ => super.getScrollPhysics(context),
      };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

/// Tiện ích Haptic Feedback tinh tế (chỉ rung nhẹ cho tương tác có ý nghĩa)
class AppHaptics {
  static void light() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void lightImpact() => light();

  static void medium() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static void mediumImpact() => medium();

  static void selection() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static void selectionClick() => selection();
}

/// Widget bọc hiệu ứng nhấn thu nhỏ (Press Scale 0.98) chuẩn iOS HIG
class PressScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool enableHaptic;
  final Duration duration;

  const PressScaleWidget({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.enableHaptic = true,
    this.duration = AppMotion.durationFast,
  });

  @override
  State<PressScaleWidget> createState() => _PressScaleWidgetState();
}

class _PressScaleWidgetState extends State<PressScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    if (widget.enableHaptic) {
      AppHaptics.light();
    }
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : _onTapDown,
      onTapUp: widget.onTap == null ? null : _onTapUp,
      onTapCancel: widget.onTap == null ? null : _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: MediaQuery.disableAnimationsOf(context)
              ? 1
              : _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
