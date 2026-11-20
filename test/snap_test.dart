import 'package:flankr_vaul/src/snap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VaulSnap', () {
    test('a fraction resolves against the room available', () {
      expect(const VaulSnap.fraction(0.5).resolve(600), 300);
      expect(const VaulSnap.fraction(1).resolve(600), 600);
    });

    test('pixels are capped at the room available', () {
      expect(const VaulSnap.pixels(200).resolve(600), 200);
      expect(const VaulSnap.pixels(900).resolve(600), 600);
    });

    test('snaps compare by kind and value', () {
      expect(const VaulSnap.fraction(0.5), const VaulSnap.fraction(0.5));
      expect(const VaulSnap.fraction(0.5), isNot(const VaulSnap.pixels(0.5)));
    });
  });

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
}
