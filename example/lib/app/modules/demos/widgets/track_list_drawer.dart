import 'package:flutter/material.dart';

/// A long list. Being a vertical ListView, it picks up the drawer's scroll
/// controller by itself, so dragging it expands the drawer first.
class TrackListDrawer extends StatelessWidget {
  const TrackListDrawer({super.key});

  static const int _count = 40;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _count,
      itemBuilder: (context, i) => ListTile(
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text('Track ${i + 1}'),
        subtitle: const Text('Drag the list up to expand first'),
      ),
    );
  }
}
