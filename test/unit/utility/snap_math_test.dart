import 'package:flankr_vaul/src/model/vaul_snap.dart';
import 'package:flankr_vaul/src/utility/snap_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveSnaps', () {
    test('without snaps the drawer rests at its content height', () {
      expect(resolveSnaps(null, available: 600, content: 240), [240]);
    });

    test('content taller than the room is capped', () {
      expect(resolveSnaps(null, available: 600, content: 900), [600]);
    });

    test('snaps come back lowest first, without duplicates', () {
      final snaps = resolveSnaps(
        const [
          VaulSnap.fraction(1),
          VaulSnap.pixels(200),
          VaulSnap.pixels(900),
        ],
        available: 600,
        content: 0,
      );
      expect(snaps, [200, 600]);
    });
  });

  group('nearestIndex', () {
    test('finds the closest value', () {
      expect(nearestIndex([100, 300, 600], 420), 1);
      expect(nearestIndex([100, 300, 600], 500), 2);
      expect(nearestIndex([100], 900), 0);
    });
  });

  group('restingSnap', () {
    const snaps = [200.0, 600.0];

    int? rest(double current, double velocity, {bool dismissible = true}) =>
        restingSnap(
          snaps: snaps,
          current: current,
          velocity: velocity,
          dismissible: dismissible,
        );

    test('a slow release settles on the nearest snap', () {
      expect(rest(350, 0), 0);
      expect(rest(450, 0), 1);
    });

    test('a slow release well below the lowest snap closes', () {
      expect(rest(100, 0), isNull);
      expect(rest(100, 0, dismissible: false), 0);
    });

    test('a fling moves one snap in its direction', () {
      expect(rest(250, -1000), 1);
      expect(rest(550, 1000), 0);
    });

    test('a fling down from the lowest snap closes, if allowed', () {
      expect(rest(200, 1000), isNull);
      expect(rest(200, 1000, dismissible: false), 0);
    });

    test('a fling up from the top stays at the top', () {
      expect(rest(600, -1000), 1);
    });
  });

  group('dragTarget', () {
    double drag(double current, double dy, {bool dismissible = true}) =>
        dragTarget(
          current: current,
          dy: dy,
          min: 200,
          max: 600,
          dismissible: dismissible,
        );

    test('follows the finger between the ends', () {
      expect(drag(400, 50), 350);
      expect(drag(400, -50), 450);
    });

    test('resists past the top', () {
      expect(drag(600, -40), 610);
    });

    test('resists below the lowest snap only when not dismissible', () {
      expect(drag(200, 40), 160);
      expect(drag(200, 40, dismissible: false), 190);
    });

    test('never goes below zero', () {
      expect(drag(10, 100), 0);
    });
  });
}
