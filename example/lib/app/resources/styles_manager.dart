import 'package:flankr_vaul_example/app/resources/color_manager.dart';
import 'package:flutter/material.dart';

abstract final class StylesManager {
  static final ThemeData light = ThemeData(colorSchemeSeed: ColorManager.seed);

  static final ThemeData dark = ThemeData(
    colorSchemeSeed: ColorManager.seed,
    brightness: Brightness.dark,
  );

  static const EdgeInsets drawerPadding = EdgeInsets.fromLTRB(24, 8, 24, 24);
  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const double gap = 16;
}
