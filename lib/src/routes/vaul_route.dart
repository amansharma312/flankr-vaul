import 'dart:async';
import 'dart:math' as math;

import 'package:flankr_vaul/src/controller/vaul_controller.dart';
import 'package:flankr_vaul/src/controller/vaul_scroll_controller.dart';
import 'package:flankr_vaul/src/model/vaul_snap.dart';
import 'package:flankr_vaul/src/model/vaul_style.dart';
import 'package:flankr_vaul/src/resources/vaul_constants.dart';
import 'package:flankr_vaul/src/utility/snap_math.dart';
import 'package:flankr_vaul/src/utility/vaul_spring.dart';
import 'package:flankr_vaul/src/widgets/drawer_insets.dart';
import 'package:flankr_vaul/src/widgets/fallback_text_style.dart';
import 'package:flankr_vaul/src/widgets/scale_back.dart';
import 'package:flankr_vaul/src/widgets/vaul_handle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// The sheet and its layout reach into the route's animation controller, which
// only the route itself may touch, so they share its library.
part '../widgets/sheet_layout.dart';
part '../widgets/vaul_sheet.dart';

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

  /// A drawer opened over this one, while it is open or animating away; this
  /// drawer scales back in step with it. Tracked here rather than through
  /// [delegatedTransition], which Flutter only applies between routes with
  /// compatible type arguments.
  final ValueNotifier<VaulRoute<dynamic>?> _above = ValueNotifier(null);

  /// Velocity (route progress per second) to start the closing spring with,
  /// set when a fling closes the drawer.
  double _closingVelocity = 0;

  /// The page this drawer opened over, which it scales back. Held so the
  /// drawer can hand the page its transition directly: Flutter only passes a
  /// [delegatedTransition] down when the page route agrees to it (Material and
  /// Cupertino do; GetX, custom `PageRouteBuilder`s and pages with another
  /// result type don't), and this works the same for every route.
  ModalRoute<dynamic>? _below;

  // ------------------------------------------------------------ route setup

  @override
  Color? get barrierColor => style.barrierColor;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration =>
      disableAnimations ? Duration.zero : VaulConstants.transitionDuration;

  @override
  Simulation? createSimulation({required bool forward}) {
    if (disableAnimations) return null;
    final velocity = forward ? 0.0 : _closingVelocity;
    _closingVelocity = 0;
    return springTo(controller!.value, forward ? 1 : 0, velocity: velocity);
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

  @override
  void install() {
    super.install();
    animation!.addListener(_claimBelow);
    animation!.addStatusListener(_onStatus);
  }

  @override
  void didChangePrevious(Route<dynamic>? previousRoute) {
    super.didChangePrevious(previousRoute);
    // A drawer below scales itself (see [_above]); only a page is handed over.
    final below =
        previousRoute is ModalRoute && previousRoute is! VaulRoute
            ? previousRoute
            : null;
    if (below != _below) _releaseBelow();
    _below = below;
    // Flutter resets the page's transition while it links the routes; take
    // it back before the next frame.
    scheduleMicrotask(_claimBelow);
  }

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    // Popping resets the page's transition too, before the closing animation
    // has run; take it back so the page eases out with the drawer.
    scheduleMicrotask(_claimBelow);
    return popped;
  }

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    super.didChangeNext(nextRoute);
    if (nextRoute is VaulRoute && nextRoute.style.scaleBackground) {
      _watchAbove(nextRoute);
    }
  }

  @override
  void dispose() {
    _releaseBelow();
    _above.dispose();
    super.dispose();
  }

  // ------------------------------------------- used by the sheet (same library)

  void _stopProgress() => controller?.stop();

  /// Restarts the opening spring from where it stands. Called once the frame
  /// that first built the drawer is on screen.
  ///
  /// Flutter times a route's opening from the first frame after the push.
  /// That frame also builds and lays out the drawer's content for the first
  /// time; when it is slow (heavy content, a first-run shader, a busy phone),
  /// the next frame's clock reads the spring as nearly over and the drawer
  /// appears without opening. Restarting here times the spring from the
  /// first frame that can show it.
  void _restartOpening() {
    final controller = this.controller;
    if (controller == null || !isActive || disableAnimations) return;
    // Only the push's own spring: not a drag, a close or a finished opening.
    if (!controller.isAnimating ||
        controller.status != AnimationStatus.forward) {
      return;
    }
    controller.animateWith(springTo(controller.value, 1));
  }

  void _setProgress(double value) {
    final clamped = value.clamp(0.0, 1.0);
    // Setting an AnimationController's value notifies its listeners even when
    // it is unchanged; skip that while a drag holds the drawer at progress 1.
    if (controller!.value == clamped) return;
    controller!.value = clamped;
  }

  TickerFuture _springProgressTo(double target, double velocity) {
    if (disableAnimations) {
      _setProgress(target);
      return TickerFuture.complete();
    }
    return controller!.animateWith(
      springTo(controller!.value, target, velocity: velocity),
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

  // ---------------------------------------------------------- scaling back

  void _onStatus(AnimationStatus status) {
    if (status.isDismissed) _releaseBelow();
  }

  /// Hands the page below this drawer's scale-back, while it is opening, open
  /// or closing. Runs on every tick, so it also wins back the page whenever
  /// Flutter resets it; once set, re-setting is a no-op.
  void _claimBelow() {
    final below = _below;
    if (below == null || !style.scaleBackground || !below.isActive) return;
    if (animation?.isDismissed ?? true) return;
    // A page route that refuses the transition is also cut off from this
    // drawer's animation (its secondary animation is parked as dismissed), so
    // it would neither rebuild as the drawer moves nor apply the transition.
    // Its secondary animation is a proxy: point it at this drawer.
    final secondary = below.secondaryAnimation;
    final drawer = animation;
    if (secondary is ProxyAnimation &&
        drawer != null &&
        secondary.parent != drawer) {
      secondary.parent = drawer;
    }
    final scale = _scaleBackground;
    // ignore: invalid_use_of_visible_for_testing_member
    if (below.receivedTransition == scale) return;
    // ignore: invalid_use_of_visible_for_testing_member
    below.receivedTransition = scale;
  }

  /// Gives the page back its own transitions once this drawer has closed.
  void _releaseBelow() {
    final below = _below;
    if (below == null) return;
    final secondary = below.secondaryAnimation;
    if (secondary is ProxyAnimation && secondary.parent == animation) {
      secondary.parent = kAlwaysDismissedAnimation;
    }
    // ignore: invalid_use_of_visible_for_testing_member
    if (below.receivedTransition != _scaleBackground) return;
    // ignore: invalid_use_of_visible_for_testing_member
    below.receivedTransition = null;
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
    if (child == null || ModalRoute.of(context) is VaulRoute) return null;
    return ScaleBack(
      animation: secondaryAnimation,
      inset: VaulConstants.pageInset,
      lift: MediaQuery.paddingOf(context).top + VaulConstants.pageLift,
      radius: VaulConstants.pageRadius,
      backdrop: style.backdropColor,
      child: child,
    );
  }
}
