import 'package:flutter/widgets.dart';

/// Gives [child] [style] as its default text style when it has none of its
/// own, so plain [Text] never renders in the debug style.
///
/// MaterialApp supplies a deliberately loud style (red, double yellow
/// underline) above every route and expects a Material to replace it; that
/// one counts as none.
class FallbackTextStyle extends StatelessWidget {
  const FallbackTextStyle({
    super.key,
    required this.style,
    required this.child,
  });

  final TextStyle style;
  final Widget child;

  static bool _isMissing(DefaultTextStyle? inherited) {
    if (inherited == null) return true;
    final style = inherited.style;
    return style.decoration == TextDecoration.underline &&
        style.decorationStyle == TextDecorationStyle.double;
  }

  @override
  Widget build(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<DefaultTextStyle>();
    if (!_isMissing(inherited)) return child;
    return DefaultTextStyle(style: style, child: child);
  }
}
