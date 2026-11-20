import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'handle.dart';
import 'scroll.dart';
import 'snap.dart';
import 'style.dart';

part 'layout.dart';
part 'sheet.dart';

/// The spring every drawer movement follows: critically damped, so it eases
/// in without bouncing past where it is going.
final SpringDescription vaulSpring = SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: 320,
  ratio: 1,
);

/// A [vaulSpring] from [from] to [to], starting at [velocity], that lands
/// exactly on [to] (a plain spring stops within a small tolerance of it).
Simulation _spring(double from, double to, double velocity) =>
    _LandingSimulation(SpringSimulation(vaulSpring, from, to, velocity), to);

class _LandingSimulation extends Simulation {
  _LandingSimulation(this._inner, this._end);

  final Simulation _inner;
  final double _end;

  @override
  double x(double time) => _inner.isDone(time) ? _end : _inner.x(time);

  @override
  double dx(double time) => _inner.isDone(time) ? 0 : _inner.dx(time);

  @override
  bool isDone(double time) => _inner.isDone(time);
}

/// Opens a drawer over the current page and returns what it was closed with.
///
/// With no [snaps] the drawer is as tall as its content. Otherwise it rests at
/// each of [snaps], lowest first, opening at [initialSnap].
Future<T?> showVaul<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  List<VaulSnap>? snaps,
  int initialSnap = 0,
  bool dismissible = true,
  VaulStyle style = const VaulStyle(),
  ValueChanged<int>? onSnap,
  bool useRootNavigator = true,
  RouteSettings? settings,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(
    VaulRoute<T>(
      builder: builder,
      snaps: snaps,
      initialSnap: initialSnap,
      dismissible: dismissible,
      style: style,
      onSnap: onSnap,
      disableAnimations: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      settings: settings,
    ),
  );
}

/// The route behind [showVaul]. Push it yourself to use it with your own
/// [Navigator] calls.
class VaulRoute<T> extends PopupRoute<T> {
  VaulRoute({
    required this.builder,
    this.snaps,
    this.initialSnap = 0,
    this.dismissible = true,
    this.style = const VaulStyle(),
    this.onSnap,
    this.disableAnimations = false,
    this.capturedThemes,
    super.settings,
  }) : assert(
         snaps == null || snaps.isNotEmpty,
         'Give at least one snap, or null to fit the content.',
       ),
       assert(initialSnap >= 0, 'initialSnap must not be negative.');

  final WidgetBuilder builder;
  final List<VaulSnap>? snaps;
  final int initialSnap;
  final bool dismissible;
  final VaulStyle style;
  final ValueChanged<int>? onSnap;

  /// Skips the drawer's motion, as when the platform asks for reduced motion.
  final bool disableAnimations;

  /// Themes from where the drawer was opened, re-applied inside it.
  final CapturedThemes? capturedThemes;

  /// Velocity (in route progress per second) to start the closing spring with,
  /// set when a fling closes the drawer.
  double _closingVelocity = 0;

  @override
  Color? get barrierColor => style.barrierColor;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration =>
      disableAnimations ? Duration.zero : const Duration(milliseconds: 400);

  @override
  Simulation? createSimulation({required bool forward}) {
    if (disableAnimations) return null;
    final velocity = forward ? 0.0 : _closingVelocity;
    _closingVelocity = 0;
    return _spring(controller!.value, forward ? 1 : 0, velocity);
  }

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      style.scaleBackground ? _scaleBackground : null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final sheet = _VaulSheet(route: this);
    return capturedThemes?.wrap(sheet) ?? sheet;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child; // The sheet moves itself.

  /// A drawer opened over this one, while it is open or animating away; this
  /// drawer scales back in step with it. Tracked here rather than through
  /// [delegatedTransition], which Flutter only applies between routes with
  /// compatible type arguments.
  final ValueNotifier<VaulRoute<dynamic>?> _above = ValueNotifier(null);

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    if (nextRoute is VaulRoute && nextRoute.style.scaleBackground) {
      _watchAbove(nextRoute);
    }
  }

  void _watchAbove(VaulRoute<dynamic> above) {
    final animation = above.animation;
    if (animation == null || _above.value == above) return;
    _above.value = above;
    void onStatus(AnimationStatus status) {
      if (!status.isDismissed) return;
      animation.removeStatusListener(onStatus);
      if (_above.value == above) _above.value = null;
    }

    animation.addStatusListener(onStatus);
  }

  @override
  void dispose() {
    _above.dispose();
    super.dispose();
  }

  void _stopProgress() => controller?.stop();

  void _setProgress(double value) {
    controller!.value = value.clamp(0.0, 1.0);
  }

  TickerFuture _springProgressTo(double target, double velocity) {
    if (disableAnimations) {
      _setProgress(target);
      return TickerFuture.complete();
    }
    return controller!.animateWith(
      _spring(controller!.value, target, velocity),
    );
  }

  /// Closes with [result], starting the closing spring at [velocity] (route
  /// progress per second, negative while closing).
  void _close(Object? result, {double velocity = 0}) {
    final navigator = this.navigator;
    if (!isActive || navigator == null) return;
    if (isCurrent) {
      _closingVelocity = velocity;
      navigator.pop(result as T?);
    } else {
      // Not on top (a drawer opened over it): take it out without animating.
      // removeRoute only takes a result on Flutter 3.32+, so it completes
      // with null here.
      navigator.removeRoute(this);
    }
  }

  /// Scales the page below back from the edges and rounds its corners, in step
  /// with how far this drawer is open.
  Widget? _scaleBackground(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    // A drawer below scales itself (see [_above]).
    if (ModalRoute.of(context) is VaulRoute) return null;
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (context, child) {
        final t = secondaryAnimation.value.clamp(0.0, 1.0);
        if (t == 0 || child == null) return child ?? const SizedBox.shrink();
        final size = MediaQuery.sizeOf(context);
        final top = MediaQuery.paddingOf(context).top + 14;
        final scale = 1 - t * math.min(26 / math.max(size.width, 1), 0.2);
        return ColoredBox(
          color: style.backdropColor,
          child: Transform.translate(
            offset: Offset(0, t * top),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(t * 12),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
