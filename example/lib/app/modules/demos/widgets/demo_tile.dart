import 'package:flankr_vaul_example/app/modules/demos/model/demo.dart';
import 'package:flutter/material.dart';

class DemoTile extends StatelessWidget {
  const DemoTile({super.key, required this.demo});

  final Demo demo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(demo.title),
        subtitle: Text(demo.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => demo.open(context),
      ),
    );
  }
}
