import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/drawer_harness.dart';

/// Drags the drawer's handle down a little and lets it spring back.
Future<void> nudgeDrawer(WidgetTester tester) async {
  await tester.timedDrag(
    find.byType(VaulHandle),
    const Offset(0, 60),
    const Duration(milliseconds: 500),
  );
  await tester.pumpAndSettle();
}

/// Opens a drawer whose content counts its builds.
Future<int Function()> openCountedDrawer(WidgetTester tester) async {
  var builds = 0;
  final context = await pumpPage(tester);
  showVaul<void>(
    context: context,
    builder: (context) => Counted(onBuild: () => builds++),
  );
  await tester.pumpAndSettle();
  return () => builds;
}

void main() {
  testWidgets('the page behind is not repainted while the drawer moves', (
    tester,
  ) async {
    final counter = PaintCounter();
    final context = await pumpPage(
      tester,
      page: CustomPaint(painter: counter, child: const SizedBox.expand()),
    );
    showVaul<void>(
      context: context,
      builder: (context) => const SizedBox(height: 200),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final atStart = counter.paints;

    await tester.pumpAndSettle();
    await nudgeDrawer(tester);
    expect(counter.paints, atStart);
  });

  testWidgets('dragging does not rebuild the content', (tester) async {
    final builds = await openCountedDrawer(tester);
    final afterOpen = builds();
    await nudgeDrawer(tester);
    expect(builds(), afterOpen);
  });

  testWidgets('the keyboard animating does not rebuild the content', (
    tester,
  ) async {
    final builds = await openCountedDrawer(tester);
    final afterOpen = builds();
    addTearDown(tester.view.resetViewInsets);
    for (var inset = 30.0; inset <= 300; inset += 30) {
      tester.view.viewInsets = FakeViewPadding(
        bottom: inset * tester.view.devicePixelRatio,
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(builds(), afterOpen);
  });

  testWidgets('a drawer keeps its state while one opens over it', (
    tester,
  ) async {
    await openCountedDrawer(tester);
    await tester.tap(find.text('Taps 0'));
    await tester.pump();
    final state = tester.state<CountedState>(find.byType(Counted));

    showVaul<void>(
      context: tester.element(find.byType(Counted)),
      builder: (context) => const SizedBox(height: 100),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 20));
    await tester.pumpAndSettle();

    expect(tester.state<CountedState>(find.byType(Counted)), same(state));
    expect(find.text('Taps 1'), findsOneWidget);
  });
}
