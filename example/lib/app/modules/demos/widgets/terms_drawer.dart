import 'package:flankr_vaul_example/app/widgets/drawer_body.dart';
import 'package:flankr_vaul_example/app/widgets/material_drawer.dart';
import 'package:flutter/widgets.dart';

class TermsDrawer extends StatelessWidget {
  const TermsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const DrawerBody(
      title: 'Accept the terms',
      message: 'This drawer stays until you choose.',
      children: [CloseDrawerButton(label: 'Accept')],
    );
  }
}
