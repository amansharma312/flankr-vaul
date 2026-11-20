import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flutter/material.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flankr_vaul',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flankr_vaul')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DemoTile(
            title: 'Fits its content',
            subtitle: 'No snaps: as tall as what is inside',
            onTap: () =>
                showVaul<void>(context: context, builder: _material(_receipt)),
          ),
          _DemoTile(
            title: 'Snap points',
            subtitle: 'Half, then full height. A long list hands off drags',
            onTap: () => showVaul<void>(
              context: context,
              snaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
              builder: _material(_longList),
            ),
          ),
          _DemoTile(
            title: 'Returns a value',
            subtitle: 'Pick a colour; the drawer closes with it',
            onTap: () async {
              final picked = await showVaul<Color>(
                context: context,
                builder: _material(_colourPicker),
              );
              if (picked == null || !context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: picked,
                  content: const Text('Picked'),
                ),
              );
            },
          ),
          _DemoTile(
            title: 'Nested',
            subtitle: 'A drawer opened from a drawer',
            onTap: () =>
                showVaul<void>(context: context, builder: _material(_nested)),
          ),
          _DemoTile(
            title: 'With a text field',
            subtitle: 'Rises above the keyboard',
            onTap: () =>
                showVaul<void>(context: context, builder: _material(_form)),
          ),
          _DemoTile(
            title: 'Not dismissible',
            subtitle: 'Resists dragging down; close it with the button',
            onTap: () => showVaul<void>(
              context: context,
              dismissible: false,
              builder: _material(_locked),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// flankr_vaul only depends on Flutter's widgets layer, so Material widgets
/// (ListTile, InkWell, TextField…) need a Material around the drawer's content.
WidgetBuilder _material(WidgetBuilder builder) =>
    (context) =>
        Material(type: MaterialType.transparency, child: builder(context));

Widget _padded(BuildContext context, List<Widget> children) {
  return SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

Widget _receipt(BuildContext context) {
  final text = Theme.of(context).textTheme;
  return _padded(context, [
    Text('Order #1042', style: text.titleLarge),
    const SizedBox(height: 4),
    Text('Delivered today, 2:14 pm', style: text.bodyMedium),
    const Divider(height: 32),
    for (final (item, price) in [
      ('Masala chai × 2', '₹120'),
      ('Bun maska', '₹60'),
      ('Delivery', '₹25'),
    ])
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
    FilledButton(
      onPressed: () => Vaul.of(context).close(),
      child: const Text('Done'),
    ),
  ]);
}

Widget _longList(BuildContext context) {
  // A vertical ListView picks up the drawer's scroll controller by itself.
  return ListView.builder(
    padding: EdgeInsets.zero,
    itemCount: 40,
    itemBuilder: (context, i) => ListTile(
      leading: CircleAvatar(child: Text('${i + 1}')),
      title: Text('Track ${i + 1}'),
      subtitle: const Text('Drag the list up to expand first'),
    ),
  );
}

Widget _colourPicker(BuildContext context) {
  const colours = [
    Colors.indigo,
    Colors.teal,
    Colors.amber,
    Colors.deepOrange,
    Colors.pink,
  ];
  return _padded(context, [
    Text('Pick a colour', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final colour in colours)
          InkResponse(
            onTap: () => Vaul.of(context).close(colour),
            child: CircleAvatar(radius: 24, backgroundColor: colour),
          ),
      ],
    ),
  ]);
}

Widget _nested(BuildContext context) {
  return _padded(context, [
    Text('First drawer', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: () => showVaul<void>(
        context: context,
        builder: (context) => _padded(context, [
          Text('Second drawer', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('The first one scaled back behind this.'),
        ]),
      ),
      child: const Text('Open another'),
    ),
  ]);
}

Widget _form(BuildContext context) {
  return _padded(context, [
    Text('Leave a note', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16),
    const TextField(
      autofocus: true,
      maxLines: 3,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Ring the bell twice…',
      ),
    ),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: () => Vaul.of(context).close(),
      child: const Text('Save'),
    ),
  ]);
}

Widget _locked(BuildContext context) {
  return _padded(context, [
    Text('Accept the terms', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    const Text('This drawer stays until you choose.'),
    const SizedBox(height: 16),
    FilledButton(
      onPressed: () => Vaul.of(context).close(),
      child: const Text('Accept'),
    ),
  ]);
}
