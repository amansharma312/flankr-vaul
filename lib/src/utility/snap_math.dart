import 'dart:math' as math;

import 'package:flankr_vaul/src/model/vaul_snap.dart';
import 'package:flankr_vaul/src/resources/vaul_constants.dart';

/// Resolves [snaps] against [available] height, lowest first, without
/// duplicates. With no snaps the drawer rests at its [content] height.
List<double> resolveSnaps(
  List<VaulSnap>? snaps, {
  required double available,
  required double content,
}) {
  if (snaps == null || snaps.isEmpty) {
    return [content.clamp(0.0, available)];
  }
  return snaps.map((snap) => snap.resolve(available)).toSet().toList()..sort();
}

/// The index of the value in [values] closest to [target].
int nearestIndex(List<double> values, double target) {
  var nearest = 0;
  for (var i = 1; i < values.length; i++) {
    if ((values[i] - target).abs() < (values[nearest] - target).abs()) {
      nearest = i;
    }
  }
  return nearest;
}

/// Where a drawer at [current] height should come to rest when let go at
/// [velocity] (logical pixels per second, positive moving down): the index of
/// one of [snaps] (lowest first), or null to close.
///
/// A fling moves one snap in its direction, closing from the lowest if the
/// drawer is [dismissible]. A slow release settles on the nearest snap, or
/// closes below [VaulConstants.closeFraction] of the lowest.
int? restingSnap({
  required List<double> snaps,
  required double current,
  required double velocity,
  required bool dismissible,
}) {
  const tolerance = VaulConstants.tolerance;
  if (velocity.abs() > VaulConstants.flingVelocity) {
    if (velocity > 0) {
      final below = snaps.lastIndexWhere((s) => s < current - tolerance);
      if (below >= 0) return below;
      return dismissible ? null : 0;
    }
    final above = snaps.indexWhere((s) => s > current + tolerance);
    return above >= 0 ? above : snaps.length - 1;
  }
  if (dismissible && current < snaps.first * VaulConstants.closeFraction) {
    return null;
  }
  return nearestIndex(snaps, current);
}

/// The height a drawer at [current] moves to when dragged by [dy] (positive
/// moving down), resisting past [max] and, unless [dismissible], below [min].
double dragTarget({
  required double current,
  required double dy,
  required double min,
  required double max,
  required bool dismissible,
}) {
  final free = current - dy;
  final pastTop = free > max || current > max;
  final pastBottom = !dismissible && (free < min || current < min);
  final target =
      pastTop || pastBottom ? current - dy * VaulConstants.rubberBand : free;
  return math.max(target, 0);
}
