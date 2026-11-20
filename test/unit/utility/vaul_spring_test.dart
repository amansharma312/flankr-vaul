import 'package:flankr_vaul/src/utility/vaul_spring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('springTo lands exactly on its target', () {
    final spring = springTo(0, 300, velocity: 500);
    var time = 0.0;
    while (!spring.isDone(time)) {
      time += 1 / 60;
    }
    expect(spring.x(time), 300);
    expect(spring.dx(time), 0);
  });

  test('springTo does not overshoot', () {
    final spring = springTo(0, 300);
    for (var time = 0.0; time < 2; time += 1 / 120) {
      expect(spring.x(time), lessThanOrEqualTo(300));
    }
  });
}
