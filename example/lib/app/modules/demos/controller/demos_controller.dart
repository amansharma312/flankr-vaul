import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flankr_vaul_example/app/modules/demos/model/demo.dart';
import 'package:flankr_vaul_example/app/modules/demos/widgets/colour_picker_drawer.dart';
import 'package:flankr_vaul_example/app/modules/demos/widgets/nested_drawer.dart';
import 'package:flankr_vaul_example/app/modules/demos/widgets/note_drawer.dart';
import 'package:flankr_vaul_example/app/modules/demos/widgets/receipt_drawer.dart';
import 'package:flankr_vaul_example/app/modules/demos/widgets/terms_drawer.dart';
import 'package:flankr_vaul_example/app/modules/demos/widgets/track_list_drawer.dart';
import 'package:flankr_vaul_example/app/widgets/drawer_body.dart';
import 'package:flankr_vaul_example/app/widgets/material_drawer.dart';
import 'package:flutter/material.dart';

/// Every demo on the screen, and how each opens its drawer.
abstract final class DemosController {
  static final List<Demo> demos = [
    Demo(
      title: 'Fits its content',
      subtitle: 'No snaps: as tall as what is inside',
      open: (context) => _open(context, (_) => const ReceiptDrawer()),
    ),
    Demo(
      title: 'Snap points',
      subtitle: 'Half, then full height. A long list hands off drags',
      open: (context) => _open(
        context,
        (_) => const TrackListDrawer(),
        snaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
      ),
    ),
    Demo(
      title: 'Returns a value',
      subtitle: 'Pick a colour; the drawer closes with it',
      open: _pickColour,
    ),
    Demo(
      title: 'Nested',
      subtitle: 'A drawer opened from a drawer',
      open: (context) => _open(context, (_) => const NestedDrawer()),
    ),
    Demo(
      title: 'With a text field',
      subtitle: 'Rises above the keyboard',
      open: (context) => _open(context, (_) => const NoteDrawer()),
    ),
    Demo(
      title: 'Not dismissible',
      subtitle: 'Resists dragging down; close it with the button',
      open: (context) =>
          _open(context, (_) => const TermsDrawer(), dismissible: false),
    ),
  ];

  /// Opens [builder] in a drawer, with a Material around it for the
  /// Material widgets the demos use.
  static Future<T?> _open<T>(
    BuildContext context,
    WidgetBuilder builder, {
    List<VaulSnap>? snaps,
    bool dismissible = true,
  }) {
    return showVaul<T>(
      context: context,
      builder: withMaterial(builder),
      snaps: snaps,
      dismissible: dismissible,
    );
  }

  static Future<void> _pickColour(BuildContext context) async {
    final picked = await _open<Color>(
      context,
      (_) => const ColourPickerDrawer(),
    );
    if (picked == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: picked, content: const Text('Picked')),
    );
  }

  /// Opens a second drawer over the one [context] is in.
  static Future<void> openNested(BuildContext context) => _open(
    context,
    (_) => const DrawerBody(
      title: 'Second drawer',
      message: 'The first one scaled back behind this.',
    ),
  );
}
