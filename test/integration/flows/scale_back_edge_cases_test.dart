import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/drawer_harness.dart';

const _pageKey = Key('page');

/// Pumps a page on a route that refuses transitions, as GetX pages do, and
/// returns a context on it.
Future<BuildContext> _pumpStubbornPage(WidgetTester tester) async {
  late BuildContext pageContext;
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute:
          (_) => StubbornRoute<void>((context) {
            pageContext = context;
            return Scaffold(
              body: SizedBox.expand(
                key: _pageKey,
                child: Center(child: Counted(onBuild: () {})),
              ),
            );
          }),
    ),
  );
  await tester.pumpAndSettle();
  return pageContext;
}

Rect _pageRect(WidgetTester tester) => tester.getRect(find.byKey(_pageKey));

void _open(BuildContext context, {WidgetBuilder? builder}) {
  showVaul<void>(
    context: context,
    builder: builder ?? (_) => const SizedBox(height: 200),
  );
}

Future<void> _tapBarrier(WidgetTester tester) async {
  await tester.tapAt(const Offset(400, 20));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('closing halfway through opening restores the page', (
    tester,
  ) async {
    final context = await _pumpStubbornPage(tester);
    final before = _pageRect(tester);
    _open(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(_pageRect(tester).width, lessThan(before.width));

    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(_pageRect(tester), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the page keeps its state through open and close', (
    tester,
  ) async {
    final context = await _pumpStubbornPage(tester);
    await tester.tap(find.text('Taps 0'));
    await tester.pump();
    final state = tester.state<CountedState>(find.byType(Counted));

    _open(context);
    await tester.pumpAndSettle();
    await _tapBarrier(tester);

    expect(tester.state<CountedState>(find.byType(Counted)), same(state));
    expect(find.text('Taps 1'), findsOneWidget);
  });

  testWidgets('opening twice in a row restores the page each time', (
    tester,
  ) async {
    final context = await _pumpStubbornPage(tester);
    final before = _pageRect(tester);
    for (var i = 0; i < 2; i++) {
      _open(context);
      await tester.pumpAndSettle();
      expect(_pageRect(tester).width, lessThan(before.width));
      await _tapBarrier(tester);
      expect(_pageRect(tester), before);
    }
  });

  testWidgets('a page pushed from the drawer and popped leaves it working', (
    tester,
  ) async {
    final context = await _pumpStubbornPage(tester);
    final before = _pageRect(tester);
    _open(
      context,
      builder:
          (drawer) => TextButton(
            onPressed:
                () => Navigator.of(drawer).push(
                  StubbornRoute<void>(
                    (_) => const Scaffold(body: Text('Detail')),
                  ),
                ),
            child: const Text('Go'),
          ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);

    Navigator.of(tester.element(find.text('Detail'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Go'), findsOneWidget);

    await _tapBarrier(tester);
    expect(_pageRect(tester), before);
    expect(tester.takeException(), isNull);
  });
}
