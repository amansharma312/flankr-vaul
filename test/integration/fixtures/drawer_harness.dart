import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The test surface is 800×600 with no padding, so a drawer can be at most
// 600 - 24 (the default top gap) = 576 tall.
const double screenHeight = 600;
const double available = 576;

/// Opens a drawer from a button and records what it closed with.
class Harness {
  Object? result = 'not closed';
  bool closed = false;
  final snaps = <int>[];
}

Future<Harness> openDrawer(
  WidgetTester tester, {
  required WidgetBuilder builder,
  List<VaulSnap>? drawerSnaps,
  int initialSnap = 0,
  bool dismissible = true,
  VaulStyle style = const VaulStyle(),
  bool disableAnimations = false,
}) async {
  final harness = Harness();
  if (disableAnimations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder:
            (context) => Scaffold(
              body: SizedBox.expand(
                key: const Key('page'),
                child: Center(
                  child: TextButton(
                    onPressed: () async {
                      harness.result = await showVaul<Object>(
                        context: context,
                        builder: builder,
                        snaps: drawerSnaps,
                        initialSnap: initialSnap,
                        dismissible: dismissible,
                        style: style,
                        onSnap: harness.snaps.add,
                      );
                      harness.closed = true;
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  if (disableAnimations) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
  return harness;
}

/// The top edge of the drawer on screen.
double drawerTop(WidgetTester tester) =>
    tester.getTopLeft(find.byType(VaulHandle)).dy;

Widget fixedContent(BuildContext context) =>
    const SizedBox(height: 200, child: Text('Content'));

/// Counts how often it paints.
class PaintCounter extends CustomPainter {
  int paints = 0;

  @override
  void paint(Canvas canvas, Size size) => paints++;

  @override
  bool shouldRepaint(PaintCounter oldDelegate) => false;
}

/// Counts how often it is built, and keeps a tap count as state.
class Counted extends StatefulWidget {
  const Counted({super.key, required this.onBuild});

  final VoidCallback onBuild;

  @override
  State<Counted> createState() => CountedState();
}

class CountedState extends State<Counted> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return GestureDetector(
      onTap: () => setState(() => taps++),
      child: SizedBox(height: 200, child: Text('Taps $taps')),
    );
  }
}

/// Pumps an app around [page] (a blank page by default) and returns a context
/// on it to open drawers from.
Future<BuildContext> pumpPage(WidgetTester tester, {Widget? page}) async {
  late BuildContext pageContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            pageContext = context;
            return page ?? const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return pageContext;
}
