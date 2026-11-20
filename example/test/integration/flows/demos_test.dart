import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flankr_vaul_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const demos = [
  'Fits its content',
  'Snap points',
  'Returns a value',
  'Nested',
  'With a text field',
  'Not dismissible',
];

void main() {
  for (final size in const [Size(375, 812), Size(800, 600)]) {
    for (final demo in demos) {
      testWidgets('$demo opens and closes cleanly at $size', (tester) async {
        tester.view.physicalSize = size * tester.view.devicePixelRatio;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const DemoApp());
        await tester.tap(find.text(demo));
        await tester.pumpAndSettle();
        expect(find.byType(VaulHandle), findsOneWidget);

        if (demo == 'Nested') {
          await tester.tap(find.text('Open another'));
          await tester.pumpAndSettle();
          expect(find.byType(VaulHandle), findsNWidgets(2));
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
        }
        if (demo == 'Snap points') {
          await tester.tap(find.byType(VaulHandle));
          await tester.pumpAndSettle();
          await tester.drag(find.text('Track 3'), const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        if (demo == 'Returns a value') {
          await tester.tap(find.byType(CircleAvatar).first);
          await tester.pumpAndSettle();
          expect(find.byType(VaulHandle), findsNothing);
          expect(find.byType(SnackBar), findsOneWidget);
          return;
        }
        final close = switch (demo) {
          'Fits its content' => 'Done',
          'With a text field' => 'Save',
          'Not dismissible' => 'Accept',
          _ => null,
        };
        if (close != null) {
          await tester.tap(find.text(close));
        } else {
          await tester.tapAt(const Offset(10, 10));
        }
        await tester.pumpAndSettle();
        expect(find.byType(VaulHandle), findsNothing);
      });
    }
  }
}
