import 'package:flutter/widgets.dart';

import 'controller.dart';

/// The grab handle at the top of a drawer. Tapping it moves the drawer to its
/// next snap, wrapping back to the lowest.
class VaulHandle extends StatelessWidget {
  const VaulHandle({
    super.key,
    required this.color,
    this.width = 36,
    this.height = 5,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final controller = Vaul.maybeOf(context);
    final pill = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height),
      ),
    );
    return Semantics(
      button: controller != null,
      label: controller != null ? 'Resize drawer' : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // The number of snaps is only known once the drawer is laid out, so
        // it is read at tap time.
        onTap: controller == null ? null : () => _cycle(controller),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(child: pill),
        ),
      ),
    );
  }

  static void _cycle(VaulController controller) {
    if (controller.snapCount < 2) return;
    controller.snapTo((controller.snap.value + 1) % controller.snapCount);
  }
}
