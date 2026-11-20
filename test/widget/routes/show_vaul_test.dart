import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration/fixtures/drawer_harness.dart';

void main() {
  testWidgets('without snaps it opens to fit its content', (tester) async {
    await openDrawer(tester, builder: fixedContent);
    expect(find.text('Content'), findsOneWidget);
    // Handle (5 + 2 × 10 padding) plus 200 of content.
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - 225));
  });

  testWidgets('it opens at the initial snap', (tester) async {
    await openDrawer(
      tester,
      builder: fixedContent,
      drawerSnaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
    );
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - available / 2));
  });

  testWidgets('it can open at a higher snap', (tester) async {
    await openDrawer(
      tester,
      builder: fixedContent,
      drawerSnaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
      initialSnap: 1,
    );
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - available));
  });

  testWidgets('a short drag down springs back', (tester) async {
    final harness = await openDrawer(tester, builder: fixedContent);
    final top = drawerTop(tester);
    await tester.timedDrag(
      find.byType(VaulHandle),
      const Offset(0, 30),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(drawerTop(tester), moreOrLessEquals(top));
    expect(harness.closed, isFalse);
  });

  testWidgets('a long drag down closes it', (tester) async {
    final harness = await openDrawer(tester, builder: fixedContent);
    await tester.timedDrag(
      find.byType(VaulHandle),
      const Offset(0, 150),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);
    expect(harness.closed, isTrue);
    expect(harness.result, isNull);
  });

  testWidgets('a quick flick down closes it', (tester) async {
    final harness = await openDrawer(tester, builder: fixedContent);
    await tester.fling(find.byType(VaulHandle), const Offset(0, 100), 1500);
    await tester.pumpAndSettle();
    expect(harness.closed, isTrue);
  });

  testWidgets('a flick up moves to the next snap', (tester) async {
    final harness = await openDrawer(
      tester,
      builder: fixedContent,
      drawerSnaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
    );
    await tester.fling(find.byType(VaulHandle), const Offset(0, -100), 1500);
    await tester.pumpAndSettle();
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - available));
    expect(harness.snaps, [1]);
  });

  testWidgets('a flick down from a higher snap stops at the one below', (
    tester,
  ) async {
    final harness = await openDrawer(
      tester,
      builder: fixedContent,
      drawerSnaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
      initialSnap: 1,
    );
    await tester.fling(find.byType(VaulHandle), const Offset(0, 100), 1500);
    await tester.pumpAndSettle();
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - available / 2));
    expect(harness.closed, isFalse);
  });

  testWidgets('a drawer that is not dismissible will not close', (
    tester,
  ) async {
    final harness = await openDrawer(
      tester,
      builder: fixedContent,
      dismissible: false,
    );
    final top = drawerTop(tester);
    await tester.fling(find.byType(VaulHandle), const Offset(0, 150), 2000);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    expect(harness.closed, isFalse);
    expect(drawerTop(tester), moreOrLessEquals(top));
  });

  testWidgets('tapping the barrier closes it', (tester) async {
    final harness = await openDrawer(tester, builder: fixedContent);
    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    expect(harness.closed, isTrue);
  });

  testWidgets('Vaul.of(context).close returns a result', (tester) async {
    final harness = await openDrawer(
      tester,
      builder:
          (context) => TextButton(
            onPressed: () => Vaul.of(context).close('picked'),
            child: const Text('Pick'),
          ),
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    expect(harness.result, 'picked');
  });

  testWidgets('snapTo and the handle move between snaps', (tester) async {
    late VaulController controller;
    final harness = await openDrawer(
      tester,
      builder: (context) {
        controller = Vaul.of(context);
        return const SizedBox.shrink();
      },
      drawerSnaps: const [
        VaulSnap.pixels(150),
        VaulSnap.pixels(300),
        VaulSnap.fraction(1),
      ],
    );
    controller.snapTo(2);
    await tester.pumpAndSettle();
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - available));
    expect(controller.snap.value, 2);

    await tester.tap(find.byType(VaulHandle)); // wraps around to the lowest
    await tester.pumpAndSettle();
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - 150));
    expect(harness.snaps, [2, 0]);
    expect(controller.extent.value, moreOrLessEquals(150));
  });

  testWidgets('dragging up a list grows the drawer before scrolling', (
    tester,
  ) async {
    await openDrawer(
      tester,
      builder:
          (context) => ListView.builder(
            itemCount: 50,
            itemBuilder:
                (context, i) => SizedBox(height: 50, child: Text('Row $i')),
          ),
      drawerSnaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
    );
    await tester.timedDrag(
      find.text('Row 1'),
      const Offset(0, -200),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    // Grew to the tallest snap; the list itself did not scroll.
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - available));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, 0);

    // Now at the top snap, dragging up scrolls the list.
    await tester.drag(find.text('Row 1'), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - available));
  });

  testWidgets('dragging down from the top of a list pulls the drawer down', (
    tester,
  ) async {
    final harness = await openDrawer(
      tester,
      builder:
          (context) => ListView.builder(
            itemCount: 50,
            itemBuilder:
                (context, i) => SizedBox(height: 50, child: Text('Row $i')),
          ),
      drawerSnaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
      initialSnap: 1,
    );
    await tester.timedDrag(
      find.text('Row 1'),
      const Offset(0, 200),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - available / 2));
    expect(harness.closed, isFalse);
  });

  testWidgets('the page behind scales back while it is open', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: SizedBox.expand(
                  key: const Key('page'),
                  child: TextButton(
                    onPressed:
                        () => showVaul<void>(
                          context: context,
                          builder: fixedContent,
                        ),
                    child: const Text('Open'),
                  ),
                ),
              ),
        ),
      ),
    );
    final before = tester.getRect(find.byKey(const Key('page')));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final open = tester.getRect(find.byKey(const Key('page')));
    expect(open.width, lessThan(before.width));
    expect(open.top, greaterThan(before.top));

    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const Key('page'))), before);
  });

  testWidgets('the page behind stays put when scaling is off', (tester) async {
    await openDrawer(
      tester,
      builder: fixedContent,
      style: const VaulStyle(scaleBackground: false),
    );
    expect(
      tester.getRect(find.byKey(const Key('page'))),
      const Rect.fromLTWH(0, 0, 800, screenHeight),
    );
  });

  testWidgets('with reduced motion it opens in a single frame', (tester) async {
    await openDrawer(tester, builder: fixedContent, disableAnimations: true);
    expect(drawerTop(tester), moreOrLessEquals(screenHeight - 225));
  });

  testWidgets('it rises above the keyboard', (tester) async {
    await openDrawer(tester, builder: fixedContent);
    final top = drawerTop(tester);
    // View insets are in physical pixels.
    tester.view.viewInsets = FakeViewPadding(
      bottom: 300 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(drawerTop(tester), moreOrLessEquals(top - 300));
  });

  testWidgets('plain text gets a default style outside a Scaffold', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Center(
                child: GestureDetector(
                  onTap:
                      () => showVaul<void>(
                        context: context,
                        builder: (context) => const Text('Plain'),
                      ),
                  child: const Text('Open', textDirection: TextDirection.ltr),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final style = DefaultTextStyle.of(tester.element(find.text('Plain'))).style;
    expect(style.decoration, TextDecoration.none);
    expect(style.fontSize, 14);
  });

  testWidgets('a drawer opened from a drawer scales the first one back', (
    tester,
  ) async {
    await openDrawer(
      tester,
      builder:
          (context) => SizedBox(
            key: const Key('first'),
            height: 200,
            child: TextButton(
              onPressed:
                  () => showVaul<void>(
                    context: context,
                    builder: (context) => const SizedBox(height: 100),
                  ),
              child: const Text('Again'),
            ),
          ),
    );
    final before = tester.getRect(find.byKey(const Key('first')));
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();
    expect(find.byType(VaulHandle), findsNWidgets(2));
    final behind = tester.getRect(find.byKey(const Key('first')));
    expect(behind.width, lessThan(before.width));

    await tester.tapAt(const Offset(400, 50));
    await tester.pumpAndSettle();
    expect(find.byType(VaulHandle), findsOneWidget);
    expect(tester.getRect(find.byKey(const Key('first'))), before);
  });
}
