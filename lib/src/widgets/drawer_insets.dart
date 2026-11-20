import 'package:flutter/widgets.dart';

/// Lifts [child] above the on-screen keyboard.
///
/// Only this widget depends on the keyboard's insets, which change every
/// frame while the keyboard animates; [child] is not rebuilt for them.
class KeyboardLift extends StatelessWidget {
  const KeyboardLift({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}

/// Tells [child] it sits above the keyboard and below the status bar, so it
/// sees neither as insets of its own.
class ContentInsets extends StatelessWidget {
  const ContentInsets({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: child,
      ),
    );
  }
}
