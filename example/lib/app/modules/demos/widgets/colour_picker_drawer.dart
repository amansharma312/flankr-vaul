import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flankr_vaul_example/app/resources/color_manager.dart';
import 'package:flankr_vaul_example/app/widgets/drawer_body.dart';
import 'package:flutter/material.dart';

/// Closes its drawer with the colour tapped.
class ColourPickerDrawer extends StatelessWidget {
  const ColourPickerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerBody(
      title: 'Pick a colour',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final colour in ColorManager.swatches)
              InkResponse(
                onTap: () => Vaul.of(context).close(colour),
                child: CircleAvatar(radius: 24, backgroundColor: colour),
              ),
          ],
        ),
      ],
    );
  }
}
