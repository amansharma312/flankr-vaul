import 'package:flankr_vaul/src/resources/vaul_constants.dart';
import 'package:flutter/physics.dart';

/// The spring every drawer movement follows: critically damped, so it eases
/// in without bouncing past where it is going.
final SpringDescription vaulSpring = SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: VaulConstants.springStiffness,
  ratio: 1,
);

/// A [vaulSpring] from [from] to [to], starting at [velocity], that lands
/// exactly on [to]. A plain spring stops within a small tolerance of it.
Simulation springTo(double from, double to, {double velocity = 0}) =>
    _LandingSimulation(SpringSimulation(vaulSpring, from, to, velocity), to);

class _LandingSimulation extends Simulation {
  _LandingSimulation(this._inner, this._end);

  final Simulation _inner;
  final double _end;

  @override
  double x(double time) => _inner.isDone(time) ? _end : _inner.x(time);

  @override
  double dx(double time) => _inner.isDone(time) ? 0 : _inner.dx(time);

  @override
  bool isDone(double time) => _inner.isDone(time);
}
