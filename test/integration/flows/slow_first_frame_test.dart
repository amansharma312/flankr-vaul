import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/drawer_harness.dart';

/// How far the drawer is open, from 0 (closed) to 1 (at its snap).
double _openness(WidgetTester tester, double restingTop) {
  final top = tester.getTopLeft(find.byType(VaulHandle)).dy;
  return (screenHeight - top) / (screenHeight - restingTop);
}

void main() {
  testWidgets('a slow first frame does not skip the opening animation', (
    tester,
  ) async {
    // fixedContent is 200 tall under a 25 px handle.
    const restingTop = screenHeight - 225;
    final context = await pumpPage(tester);
    showVaul<void>(context: context, builder: fixedContent);
    // The frame that first builds the drawer, then a long gap before the
    // next one: what a heavy drawer does on a phone.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      _openness(tester, restingTop),
      lessThan(0.2),
      reason: 'the gap after the first frame must not count as animation',
    );

    // From there it animates over several frames, not in one jump.
    final steps = <double>[];
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      steps.add(_openness(tester, restingTop));
    }
    expect(steps.where((s) => s > 0.05 && s < 0.95), hasLength(greaterThan(3)));
    await tester.pumpAndSettle();
    expect(_openness(tester, restingTop), closeTo(1, 1e-6));
  });
}
