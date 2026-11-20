import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Controls the drawer a widget is inside. Get it with [Vaul.of].
abstract interface class VaulController {
  /// The index of the snap the drawer is at, or heading to, lowest first.
  ValueListenable<int> get snap;

  /// How much of the drawer is on screen, in logical pixels.
  ValueListenable<double> get extent;

  /// The number of snaps the drawer has.
  int get snapCount;

  /// Hands drags from a scroll view to the drawer. Scroll views that use the
  /// primary scroll controller (the default for vertical lists) get this
  /// automatically.
  ScrollController get scrollController;

  /// Moves the drawer to the snap at [index], lowest first.
  void snapTo(int index);

  /// Closes the drawer, completing its future with [result].
  void close([Object? result]);
}

/// Finds the drawer around a widget.
abstract final class Vaul {
  /// The [VaulController] of the drawer around [context].
  static VaulController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(
      controller != null,
      'Vaul.of() called outside a drawer opened with showVaul().',
    );
    return controller!;
  }

  /// The [VaulController] of the drawer around [context], or null outside one.
  static VaulController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VaulScope>()?.controller;
}

/// Hands a [VaulController] down to a drawer's content.
class VaulScope extends InheritedWidget {
  const VaulScope({super.key, required this.controller, required super.child});

  final VaulController controller;

  @override
  bool updateShouldNotify(VaulScope oldWidget) =>
      oldWidget.controller != controller;
}
