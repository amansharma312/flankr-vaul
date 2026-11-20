import 'package:flankr_vaul/src/resources/vaul_colors.dart';
import 'package:flutter/widgets.dart';

/// How a drawer looks.
@immutable
class VaulStyle {
  const VaulStyle({
    this.color,
    this.radius = 16,
    this.handle = true,
    this.handleColor,
    this.barrierColor = VaulColors.barrier,
    this.scaleBackground = true,
    this.backdropColor = VaulColors.backdrop,
    this.topGap = 24,
    this.maxWidth = 640,
    this.shadow = const [BoxShadow(color: VaulColors.shadow, blurRadius: 24)],
    this.textStyle,
  });

  /// The drawer's surface. Defaults to white, or near-black when the device
  /// is in dark mode.
  final Color? color;

  /// The radius of the drawer's top corners.
  final double radius;

  /// Whether to draw a grab handle at the top. Tapping it moves to the next snap.
  final bool handle;

  /// The handle's colour. Defaults to a translucent grey that suits [color].
  final Color? handleColor;

  /// The scrim over the page behind the drawer.
  final Color barrierColor;

  /// Whether the page behind scales back and rounds its corners as the
  /// drawer opens. Needs that page to be a Material or Cupertino route.
  final bool scaleBackground;

  /// What shows around the page behind while it is scaled back.
  final Color backdropColor;

  /// The space kept free above the drawer, below the status bar, at its tallest.
  final double topGap;

  /// The widest the drawer gets; it centres on wider screens.
  final double maxWidth;

  /// The drawer's shadow.
  final List<BoxShadow> shadow;

  /// The text style for the drawer's content when it opens somewhere with no
  /// default text style of its own (outside a Material or Scaffold, say).
  /// Defaults to 14pt, coloured to suit [color].
  final TextStyle? textStyle;

  TextStyle resolveTextStyle(Brightness brightness) =>
      textStyle ??
      TextStyle(
        fontSize: 14,
        color: VaulColors.text(brightness),
        decoration: TextDecoration.none,
      );

  Color resolveColor(Brightness brightness) =>
      color ?? VaulColors.surface(brightness);

  Color resolveHandleColor(Brightness brightness) =>
      handleColor ?? VaulColors.handle(brightness);

  VaulStyle copyWith({
    Color? color,
    double? radius,
    bool? handle,
    Color? handleColor,
    Color? barrierColor,
    bool? scaleBackground,
    Color? backdropColor,
    double? topGap,
    double? maxWidth,
    List<BoxShadow>? shadow,
    TextStyle? textStyle,
  }) {
    return VaulStyle(
      color: color ?? this.color,
      radius: radius ?? this.radius,
      handle: handle ?? this.handle,
      handleColor: handleColor ?? this.handleColor,
      barrierColor: barrierColor ?? this.barrierColor,
      scaleBackground: scaleBackground ?? this.scaleBackground,
      backdropColor: backdropColor ?? this.backdropColor,
      topGap: topGap ?? this.topGap,
      maxWidth: maxWidth ?? this.maxWidth,
      shadow: shadow ?? this.shadow,
      textStyle: textStyle ?? this.textStyle,
    );
  }
}
