import 'package:flutter/material.dart';

abstract final class ColorManager {
  static const Color seed = Colors.indigo;

  /// The swatches offered by the colour picker demo.
  static const List<Color> swatches = [
    Colors.indigo,
    Colors.teal,
    Colors.amber,
    Colors.deepOrange,
    Colors.pink,
  ];
}
