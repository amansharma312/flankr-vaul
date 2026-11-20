import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// What a drawer exposes to the scroll views inside it, so a drag can move the
/// drawer before (or instead of) scrolling its content.
abstract interface class VaulDriver {
  /// How much of the drawer is on screen, in logical pixels.
  double get visible;

  /// Its tallest snap, in logical pixels.
  double get maxExtent;

  void beginDrag();

  /// Moves the drawer with the finger; [dy] is positive moving down.
  void dragBy(double dy);

  /// Lets go; [velocity] is in logical pixels per second, positive moving down.
  void release(double velocity);
}

/// A [ScrollController] whose scroll views hand drags to the drawer: dragging
/// up grows the drawer to its tallest snap before the content scrolls, and
/// dragging down from the top of the content pulls the drawer down.
class VaulScrollController extends ScrollController {
  VaulScrollController(this.driver, {super.debugLabel});

  final VaulDriver driver;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _VaulScrollPosition(
      driver: driver,
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _VaulScrollPosition extends ScrollPositionWithSingleContext {
  _VaulScrollPosition({
    required this.driver,
    required super.physics,
    required super.context,
    super.oldPosition,
    super.debugLabel,
  });

  final VaulDriver driver;

  /// Whether the drawer, not the content, moved during the current drag.
  bool _movedDrawer = false;

  static const double _tolerance = 0.5;

  bool get _atTop => pixels <= minScrollExtent;

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _movedDrawer = false;
    driver.beginDrag();
    return super.drag(details, dragCancelCallback);
  }

  @override
  void applyUserOffset(double delta) {
    // delta > 0: the finger moves down.
    final growing = delta < 0 && driver.visible < driver.maxExtent - _tolerance;
    final pulling = delta > 0 && _atTop;
    if (growing || pulling) {
      _movedDrawer = true;
      driver.dragBy(delta);
      return;
    }
    super.applyUserOffset(delta);
  }

  @override
  void goBallistic(double velocity) {
    if (!_movedDrawer) {
      super.goBallistic(velocity);
      return;
    }
    _movedDrawer = false;
    // A scroll velocity is positive towards the end of the content, which is
    // the finger moving up.
    driver.release(-velocity);
    super.goBallistic(0);
  }
}
