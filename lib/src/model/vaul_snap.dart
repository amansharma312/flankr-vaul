import 'package:flutter/foundation.dart';

/// A height a drawer can come to rest at.
///
/// Give a drawer's snaps lowest first. The lowest is where it opens unless
/// you pick another `initialSnap`, and dragging below it closes the drawer.
@immutable
sealed class VaulSnap {
  const VaulSnap();

  /// A fraction (0–1] of the tallest the drawer can be.
  const factory VaulSnap.fraction(double value) = _FractionSnap;

  /// A fixed height in logical pixels, capped at the tallest the drawer can be.
  const factory VaulSnap.pixels(double value) = _PixelSnap;

  /// This snap's height when the drawer can be at most [available] tall.
  double resolve(double available);
}

final class _FractionSnap extends VaulSnap {
  const _FractionSnap(this.value)
    : assert(value > 0 && value <= 1, 'A fraction snap must be in (0, 1].');

  final double value;

  @override
  double resolve(double available) => available * value;

  @override
  bool operator ==(Object other) =>
      other is _FractionSnap && other.value == value;

  @override
  int get hashCode => Object.hash(_FractionSnap, value);

  @override
  String toString() => 'VaulSnap.fraction($value)';
}

final class _PixelSnap extends VaulSnap {
  const _PixelSnap(this.value)
    : assert(value > 0, 'A pixel snap must be positive.');

  final double value;

  @override
  double resolve(double available) => value < available ? value : available;

  @override
  bool operator ==(Object other) => other is _PixelSnap && other.value == value;

  @override
  int get hashCode => Object.hash(_PixelSnap, value);

  @override
  String toString() => 'VaulSnap.pixels($value)';
}
