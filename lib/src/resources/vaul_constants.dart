/// The numbers that tune how a drawer moves and looks, in one place.
abstract final class VaulConstants {
  /// Above this speed (logical pixels per second) a release counts as a
  /// fling and moves one snap in its direction, instead of to the nearest.
  static const double flingVelocity = 500;

  /// Released below this fraction of its lowest snap, the drawer closes.
  static const double closeFraction = 0.75;

  /// How much a drag past either end still moves the drawer.
  static const double rubberBand = 0.25;

  /// Within this many logical pixels, two heights count as the same.
  static const double tolerance = 1;

  /// The stiffness of the critically damped spring every movement follows.
  static const double springStiffness = 320;

  /// Used only if a route animates without its spring.
  static const Duration transitionDuration = Duration(milliseconds: 400);

  /// How far the page behind pulls in from each side, fully open.
  static const double pageInset = 13;

  /// How far the page behind drops, below the status bar, fully open.
  static const double pageLift = 14;

  /// The corner radius of the page behind, fully open.
  static const double pageRadius = 12;

  /// How far a drawer pulls in from each side while another is open over it.
  static const double nestedInset = 16;

  /// The most any scale-back shrinks its child.
  static const double maxScaleBack = 0.2;

  /// The grab handle's pill.
  static const double handleWidth = 36;
  static const double handleHeight = 5;
  static const double handlePadding = 10;
}
