part of '../routes/vaul_route.dart';

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

  /// Ticks whenever the drawer moves.
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

  /// Whether the route is open and not on its way out.
  bool get _canMove =>
      _route.isActive && _progress.status != AnimationStatus.reverse;

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
    if (_canMove) _stop();
  }

  @override
  void dragBy(double dy) {
    if (!_canMove) return;
    _stop();
    _setVisible(
      dragTarget(
        current: visible,
        dy: dy,
        min: _lowest,
        max: maxExtent,
        dismissible: _route.dismissible,
      ),
    );
  }

  @override
  void release(double velocity) {
    if (!_canMove) return;
    final index = restingSnap(
      snaps: _snaps,
      current: visible,
      velocity: velocity,
      dismissible: _route.dismissible,
    );
    if (index == null) {
      _route._close(null, velocity: -velocity / math.max(_anchorHeight, 1));
    } else {
      _settle(index, velocity: velocity);
    }
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
    if (_canMove) _settle(index.clamp(0, _snaps.length - 1));
  }

  @override
  void close([Object? result]) => _route._close(result);

  // --------------------------------------------------------------- motion

  void _stop() {
    if (_anchor.isAnimating) _anchor.stop();
    if (_progress.isAnimating) _route._stopProgress();
  }

  /// Puts the drawer at [height] right away, without changing which snap it
  /// is resting at.
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
    final current = visible;
    _resting = false;
    if (_disableAnimations) {
      _route._setProgress(1);
      _rest(index);
      return;
    }
    if (current < _lowest && index == 0) {
      // Below the lowest snap: spring the route back up, so the page behind
      // scales with it.
      _anchor.value = _lowest;
      _route
          ._springProgressTo(1, -velocity / math.max(_lowest, 1))
          .then((_) => _rest(index));
      return;
    }
    // At or above the lowest snap, or flung up from below it: hold progress
    // at 1 and spring the height.
    _anchor.value = current;
    _route._setProgress(1);
    _anchor
        .animateWith(springTo(current, _snaps[index], velocity: -velocity))
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
    final surface = style.resolveColor(brightness);
    final top = BorderRadius.vertical(top: Radius.circular(style.radius));
    final fitsContent = _route.snaps == null;
    final content = ContentInsets(
      child: FallbackTextStyle(
        style: style.resolveTextStyle(brightness),
        child: Builder(builder: _route.builder),
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
          color: surface,
          borderRadius: top,
          boxShadow: style.shadow,
        ),
        child: ClipRRect(
          borderRadius: top,
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
          child: ValueListenableBuilder<VaulRoute<dynamic>?>(
            valueListenable: _route._above,
            child: KeyboardLift(
              child: _SheetLayout(
                state: this,
                topReserve: MediaQuery.paddingOf(context).top + style.topGap,
                maxWidth: style.maxWidth,
                fillColor: surface,
                child: RepaintBoundary(child: sheet),
              ),
            ),
            // Scales back while another drawer is open over this one.
            builder:
                (context, above, child) => ScaleBack(
                  animation: above?.animation ?? kAlwaysDismissedAnimation,
                  inset: VaulConstants.nestedInset,
                  alignment: Alignment.bottomCenter,
                  child: child!,
                ),
          ),
        ),
      ),
    );
  }
}
