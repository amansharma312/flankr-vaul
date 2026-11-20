import 'package:flankr_vaul_example/app/modules/demos/controller/demos_controller.dart';
import 'package:flankr_vaul_example/app/widgets/drawer_body.dart';
import 'package:flutter/material.dart';

class NestedDrawer extends StatelessWidget {
  const NestedDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerBody(
      title: 'First drawer',
      children: [
        FilledButton(
          onPressed: () => DemosController.openNested(context),
          child: const Text('Open another'),
        ),
      ],
    );
  }
}
