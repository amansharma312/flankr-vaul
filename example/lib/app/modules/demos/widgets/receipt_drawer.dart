import 'package:flankr_vaul_example/app/widgets/drawer_body.dart';
import 'package:flankr_vaul_example/app/widgets/material_drawer.dart';
import 'package:flutter/material.dart';

class ReceiptDrawer extends StatelessWidget {
  const ReceiptDrawer({super.key});

  static const _lines = [
    ('Masala chai × 2', '₹120'),
    ('Bun maska', '₹60'),
    ('Delivery', '₹25'),
  ];

  @override
  Widget build(BuildContext context) {
    return DrawerBody(
      title: 'Order #1042',
      message: 'Delivered today, 2:14 pm',
      children: [
        const Divider(height: 16),
        for (final (item, price) in _lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text(item)),
                Text(price),
              ],
            ),
          ),
        const Divider(height: 32),
        const CloseDrawerButton(label: 'Done'),
      ],
    );
  }
}
