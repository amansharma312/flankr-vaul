import 'package:flutter/widgets.dart';

/// One entry on the demo screen: what it shows, and how to open it.
@immutable
class Demo {
  const Demo({required this.title, required this.subtitle, required this.open});

  final String title;
  final String subtitle;
  final Future<void> Function(BuildContext context) open;
}
