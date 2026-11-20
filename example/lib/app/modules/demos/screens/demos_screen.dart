import 'package:flankr_vaul_example/app/modules/demos/controller/demos_controller.dart';
import 'package:flankr_vaul_example/app/modules/demos/widgets/demo_tile.dart';
import 'package:flankr_vaul_example/app/resources/styles_manager.dart';
import 'package:flutter/material.dart';

class DemosScreen extends StatelessWidget {
  const DemosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flankr_vaul')),
      body: ListView(
        padding: StylesManager.screenPadding,
        children: [
          for (final demo in DemosController.demos) DemoTile(demo: demo),
        ],
      ),
    );
  }
}
