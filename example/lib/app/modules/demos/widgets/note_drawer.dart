import 'package:flankr_vaul_example/app/widgets/drawer_body.dart';
import 'package:flankr_vaul_example/app/widgets/material_drawer.dart';
import 'package:flutter/material.dart';

class NoteDrawer extends StatelessWidget {
  const NoteDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const DrawerBody(
      title: 'Leave a note',
      children: [
        TextField(
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ring the bell twice…',
          ),
        ),
        SizedBox(height: 16),
        CloseDrawerButton(label: 'Save'),
      ],
    );
  }
}
