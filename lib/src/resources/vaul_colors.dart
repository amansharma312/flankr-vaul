import 'package:flutter/widgets.dart';

/// Default colours, picked for the device's light or dark mode.
abstract final class VaulColors {
  static const Color barrier = Color(0x66000000);
  static const Color backdrop = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color shadow = Color(0x1F000000);

  static Color surface(Brightness brightness) => _pick(
    brightness,
    light: const Color(0xFFFFFFFF),
    dark: const Color(0xFF1C1C1E),
  );

  static Color handle(Brightness brightness) => _pick(
    brightness,
    light: const Color(0x33000000),
    dark: const Color(0x52FFFFFF),
  );

  static Color text(Brightness brightness) => _pick(
    brightness,
    light: const Color(0xDE000000),
    dark: const Color(0xFFFFFFFF),
  );

  static Color _pick(
    Brightness brightness, {
    required Color light,
    required Color dark,
  }) => brightness == Brightness.dark ? dark : light;
}
