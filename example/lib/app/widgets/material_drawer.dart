import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flutter/material.dart';

/// flankr_vaul only depends on Flutter's widgets layer, so Material widgets
/// (ListTile, InkWell, TextField…) need a Material around a drawer's content.
/// Wraps [builder]'s content in a transparent one.
WidgetBuilder withMaterial(WidgetBuilder builder) =>
    (context) =>
        Material(type: MaterialType.transparency, child: builder(context));

/// A full-width button that closes the drawer it is in.
class CloseDrawerButton extends StatelessWidget {
  const CloseDrawerButton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => Vaul.of(context).close(),
      child: Text(label),
    );
  }
}
