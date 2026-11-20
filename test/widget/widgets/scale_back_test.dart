import 'package:flankr_vaul/src/widgets/scale_back.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factor pulls a box in by the inset on each side', () {
    expect(ScaleBack.factor(0, width: 400, inset: 20), 1);
    expect(ScaleBack.factor(1, width: 400, inset: 20), 0.9);
    expect(ScaleBack.factor(0.5, width: 400, inset: 20), 0.95);
  });

  test('factor never shrinks a narrow box past the limit', () {
    expect(ScaleBack.factor(1, width: 50, inset: 20), 0.8);
  });

  testWidgets('its child keeps its element at every value', (tester) async {
    final animation = AnimationController(vsync: const TestVSync());
    addTearDown(animation.dispose);
    const key = Key('child');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ScaleBack(
          animation: animation,
          inset: 20,
          radius: 12,
          child: const SizedBox.expand(key: key),
        ),
      ),
    );
    final element = tester.element(find.byKey(key));
    animation.value = 1;
    await tester.pump();
    expect(tester.element(find.byKey(key)), same(element));
    expect(tester.getRect(find.byKey(key)).width, lessThan(800));
    animation.value = 0;
    await tester.pump();
    expect(tester.element(find.byKey(key)), same(element));
    expect(tester.getRect(find.byKey(key)).width, 800);
  });
}
