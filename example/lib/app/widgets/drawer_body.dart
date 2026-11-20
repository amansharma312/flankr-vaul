import 'package:flankr_vaul_example/app/resources/styles_manager.dart';
import 'package:flutter/material.dart';

/// The padded column most demo drawers are made of: a [title], an optional
/// [message], then [children].
class DrawerBody extends StatelessWidget {
  const DrawerBody({
    super.key,
    required this.title,
    this.message,
    this.children = const [],
  });

  final String title;
  final String? message;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final message = this.message;
    return SafeArea(
      top: false,
      child: Padding(
        padding: StylesManager.drawerPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: text.titleLarge),
            if (message != null) ...[const SizedBox(height: 8), Text(message)],
            if (children.isNotEmpty) const SizedBox(height: StylesManager.gap),
            ...children,
          ],
        ),
      ),
    );
  }
}
