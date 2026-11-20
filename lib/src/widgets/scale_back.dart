import 'dart:math' as math;

import 'package:flankr_vaul/src/resources/vaul_colors.dart';
import 'package:flankr_vaul/src/resources/vaul_constants.dart';
import 'package:flutter/widgets.dart';

/// Shrinks [child] in from the sides as [animation] runs from 0 to 1, and
/// optionally drops it, rounds its corners and shows [backdrop] around it.
///
/// The same widgets wrap [child] at every value, so it keeps its state and is
/// never rebuilt from scratch when the animation starts or ends. Only layers
/// move: [child] is not repainted.
class ScaleBack extends StatelessWidget {
  const ScaleBack({
    super.key,
    required this.animation,
    required this.inset,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.lift = 0,
    this.radius = 0,
    this.backdrop,
  });

  final Animation<double> animation;

  /// How far [child] pulls in from each side at 1, in logical pixels.
  final double inset;

  /// Which point stays put while [child] shrinks.
  final Alignment alignment;

  /// How far [child] moves down at 1.
  final double lift;

  /// The corner radius at 1.
  final double radius;

  /// Shown around [child] while it is shrunk.
  final Color? backdrop;

  final Widget child;

  /// The scale that pulls a [width]-wide box in by [inset] on each side,
  /// [t] of the way.
  static double factor(
    double t, {
    required double width,
    required double inset,
  }) {
    final full = math.min(
      2 * inset / math.max(width, 1),
      VaulConstants.maxScaleBack,
    );
    return 1 - t * full;
  }

  @override
  Widget build(BuildContext context) {
    final backdrop = this.backdrop;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0);
        final width = MediaQuery.sizeOf(context).width;
        final shrunk = t > 0;
        final moved = Transform.translate(
          offset: Offset(0, t * lift),
          child: Transform.scale(
            scale: factor(t, width: width, inset: inset),
            alignment: alignment,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(t * radius),
              clipBehavior: shrunk && radius > 0 ? Clip.antiAlias : Clip.none,
              child: child,
            ),
          ),
        );
        // A ColoredBox takes every tap in its bounds, so it is only added
        // when there is a backdrop to show. [backdrop] is fixed for the
        // widget's life, so the tree's shape still never changes.
        if (backdrop == null) return moved;
        return ColoredBox(
          color: shrunk ? backdrop : VaulColors.transparent,
          child: moved,
        );
      },
    );
  }
}
