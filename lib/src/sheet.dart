part of 'route.dart';

/// Above this speed (logical pixels per second) a release counts as a fling
/// and moves one snap in its direction, instead of to the nearest.
const double _flingVelocity = 500;

/// Released below this fraction of its lowest snap, the drawer closes.
const double _closeFraction = 0.75;

/// How much a drag past either end still moves the drawer.
const double _rubberBand = 0.25;

class _VaulSheet extends StatefulWidget {
  const _VaulSheet({required this.route});

  final VaulRoute<dynamic> route;

  @override
  State<_VaulSheet> createState() => _VaulSheetState();
}

/// The drawer's position is `progress × anchor`:
///
///  * `progress` is the route's own animation, 0 (closed) to 1 (at the lowest
///    snap or above). Pushing and popping the route animate it, and the page
///    behind scales with it.
///  * `anchor` is the height the drawer has at `progress` 1: a snap when it is
///    resting there, or a free height while it is dragged or springing between
///    snaps.
class _VaulSheetState extends State<_VaulSheet>
    with SingleTickerProviderStateMixin
    implements VaulController, VaulDriver {
  VaulRoute<dynamic> get _route => widget.route;
  Animation<double> get _progress => _route.animation!;

  /// The free height, used while [_resting] is false.
  late final AnimationController _anchor = AnimationController.unbounded(
    vsync: this,
  );
  bool _resting = true;

  late final ValueNotifier<int> _snap = ValueNotifier(_route.initialSnap);
  final ValueNotifier<double> _extent = ValueNotifier(0);
  late final VaulScrollController _scrollController = VaulScrollController(
    this,
    debugLabel: 'VaulScrollController',
  );
  late final Listenable _motion = Listenable.merge([_progress, _anchor]);

  List<double> _snaps = const [0];

  @override
  void initState() {
    super.initState();
    _motion.addListener(_updateExtent);
    _progress.addStatusListener(_onRouteStatus);
  }

  @override
  void dispose() {
    _motion.removeListener(_updateExtent);
    _progress.removeStatusListener(_onRouteStatus);
    _anchor.dispose();
    _snap.dispose();
    _extent.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _disableAnimations =>
      _route.disableAnimations ||
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  double get _lowest => _snaps.first;

  double get _anchorHeight =>
      _resting
          ? _snaps[_snap.value.clamp(0, _snaps.length - 1)]
          : _anchor.value;

  // ---------------------------------------------------------------- geometry

  /// Called during layout with the room the drawer has and its content's
  /// height. Snaps are resolved here, so the first frame is already right.
  void _didLayout(double available, double content) {
    final snaps = resolveSnaps(
      _route.snaps,
      available: available,
      content: content,
    );
    if (listEquals(snaps, _snaps)) return;
    _snaps = snaps;
    if (_snap.value >= snaps.length) {
      // Fewer distinct snaps than asked for (two resolved to one height).
      _resting = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _snap.value = snaps.length - 1;
      });
    }
  }

  void _updateExtent() => _extent.value = visible;

  void _onRouteStatus(AnimationStatus status) {
    // Closing from outside (the barrier, back button, Navigator.pop): freeze
    // the drawer's height and let the route animate it away.
    if (status == AnimationStatus.reverse && _anchor.isAnimating) {
      _anchor.stop();
    }
  }

  // ------------------------------------------------------------ VaulDriver

  @override
  double get visible => _progress.value * _anchorHeight;

  @override
  double get maxExtent => _snaps.last;

  @override
  void beginDrag() {
    if (_progress.status == AnimationStatus.reverse) return;
    _stop();
  }

  @override
  void dragBy(double dy) {
    if (!_route.isActive || _progress.status == AnimationStatus.reverse) return;
    _stop();
    final current = visible;
    var target = current - dy;
    final pastTop = target > maxExtent || current > maxExtent;
    final pastBottom =
        !_route.dismissible && (target < _lowest || current < _lowest);
    if (pastTop || pastBottom) target = current - dy * _rubberBand;
    _setVisible(math.max(target, 0));
  }

  @override
  void release(double velocity) {
    if (!_route.isActive || _progress.status == AnimationStatus.reverse) return;
    final current = visible;
    final target = _pickRest(current, velocity);
    if (target == null) {
      final anchor = math.max(_anchorHeight, 1.0);
      _route._close(null, velocity: -velocity / anchor);
    } else {
      _settle(target, velocity: velocity);
    }
  }

  /// The snap index to come to rest at, or null to close.
  int? _pickRest(double current, double velocity) {
    if (velocity.abs() > _flingVelocity) {
      if (velocity > 0) {
        // Down: the next snap below, or close from the lowest.
        final below = _snaps.lastIndexWhere((s) => s < current - 1);
        if (below >= 0) return below;
        return _route.dismissible ? null : 0;
      }
      final above = _snaps.indexWhere((s) => s > current + 1);
      return above >= 0 ? above : _snaps.length - 1;
    }
    if (_route.dismissible && current < _lowest * _closeFraction) return null;
    var nearest = 0;
    for (var i = 1; i < _snaps.length; i++) {
      if ((_snaps[i] - current).abs() < (_snaps[nearest] - current).abs()) {
        nearest = i;
      }
    }
    return nearest;
  }

  // -------------------------------------------------------- VaulController

  @override
  ValueListenable<int> get snap => _snap;

  @override
  ValueListenable<double> get extent => _extent;

  @override
  int get snapCount => _snaps.length;

  @override
  ScrollController get scrollController => _scrollController;

  @override
  void snapTo(int index) {
    if (!_route.isActive || _progress.status == AnimationStatus.reverse) return;
    _settle(index.clamp(0, _snaps.length - 1));
  }

  @override
  void close([Object? result]) => _route._close(result);

  // --------------------------------------------------------------- motion

  void _stop() {
    if (_anchor.isAnimating) _anchor.stop();
    if (_progress.isAnimating) _route._stopProgress();
  }

  /// Puts the drawer at [height] right away, without changing what it is
  /// resting at.
  void _setVisible(double height) {
    _resting = false;
    if (height >= _lowest) {
      _anchor.value = height;
      _route._setProgress(1);
    } else {
      _anchor.value = _lowest;
      _route._setProgress(_lowest == 0 ? 0 : height / _lowest);
    }
  }

  /// Springs to the snap at [index], carrying on at [velocity] (logical
  /// pixels per second, positive moving down).
  void _settle(int index, {double velocity = 0}) {
    _setSnap(index);
    final target = _snaps[index];
    final current = visible;
    if (_disableAnimations) {
      _resting = true;
      _route._setProgress(1);
      _updateExtent();
      return;
    }
    if (current < _lowest && index == 0) {
      // Below the lowest snap: spring the route back up so the page behind
      // scales with it.
      _resting = false;
      _anchor.value = _lowest;
      final lowest = math.max(_lowest, 1.0);
      _route._springProgressTo(1, -velocity / lowest).then((_) => _rest(index));
      return;
    }
    // At or above the lowest snap, or flung up from below it: hold progress
    // at 1 and spring the height.
    _resting = false;
    _anchor.value = current;
    _route._setProgress(1);
    _anchor
        .animateWith(_spring(current, target, -velocity))
        .then((_) => _rest(index));
  }

  void _rest(int index) {
    if (!mounted || _snap.value != index) return;
    _resting = true;
    _updateExtent();
  }

  void _setSnap(int index) {
    if (_snap.value == index) return;
    _snap.value = index;
    _route.onSnap?.call(index);
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final style = _route.style;
    final brightness = MediaQuery.platformBrightnessOf(context);
    final media = MediaQuery.of(context);
    final fitsContent = _route.snaps == null;
    final content = MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: _withTextStyle(
          context,
          style.resolveTextStyle(brightness),
          Builder(builder: _route.builder),
        ),
      ),
    );

    final sheet = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => beginDrag(),
      onVerticalDragUpdate: (details) => dragBy(details.delta.dy),
      onVerticalDragEnd:
          (details) => release(details.velocity.pixelsPerSecond.dy),
      onVerticalDragCancel: () => release(0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.resolveColor(brightness),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(style.radius),
          ),
          boxShadow: style.shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(style.radius),
          ),
          child: Column(
            mainAxisSize: fitsContent ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (style.handle)
                VaulHandle(color: style.resolveHandleColor(brightness)),
              if (fitsContent)
                Flexible(child: content)
              else
                Expanded(child: content),
            ],
          ),
        ),
      ),
    );

    return VaulScope(
      controller: this,
      child: PrimaryScrollController(
        controller: _scrollController,
        automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
        child: Semantics(
          explicitChildNodes: true,
          child: _ScaleUnderDrawer(
            above: _route._above,
            child: Padding(
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: _SheetLayout(
                state: this,
                topReserve: media.padding.top + style.topGap,
                maxWidth: style.maxWidth,
                fillColor: style.resolveColor(brightness),
                child: RepaintBoundary(child: sheet),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Gives the content [fallback] as its default text style when it has none
  /// of its own, so plain [Text] never renders in the debug style.
  ///
  /// MaterialApp supplies a deliberately loud style (red, double yellow
  /// underline) above every route and expects a Material to replace it; that
  /// one counts as none.
  static Widget _withTextStyle(
    BuildContext context,
    TextStyle fallback,
    Widget child,
  ) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<DefaultTextStyle>();
    final missing =
        inherited == null ||
        (inherited.style.decoration == TextDecoration.underline &&
            inherited.style.decorationStyle == TextDecorationStyle.double);
    if (!missing) return child;
    return DefaultTextStyle(style: fallback, child: child);
  }
}

/// Scales a drawer back, narrower and anchored at the bottom, while another
/// drawer is open over it.
class _ScaleUnderDrawer extends StatelessWidget {
  const _ScaleUnderDrawer({required this.above, required this.child});

  final ValueListenable<VaulRoute<dynamic>?> above;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VaulRoute<dynamic>?>(
      valueListenable: above,
      child: child,
      builder: (context, route, child) {
        final animation = route?.animation;
        if (animation == null) return child!;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final t = animation.value.clamp(0.0, 1.0);
            final width = MediaQuery.sizeOf(context).width;
            return Transform.scale(
              scale: 1 - t * math.min(32 / math.max(width, 1), 0.2),
              alignment: Alignment.bottomCenter,
              child: child,
            );
          },
        );
      },
    );
  }
}
