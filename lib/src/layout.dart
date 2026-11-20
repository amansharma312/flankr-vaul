part of 'route.dart';

/// Lays the drawer out against the bottom edge and slides it to its current
/// height at paint time, so dragging repaints without relaying out.
class _SheetLayout extends SingleChildRenderObjectWidget {
  const _SheetLayout({
    required this.state,
    required this.topReserve,
    required this.maxWidth,
    required this.fillColor,
    super.child,
  });

  final _VaulSheetState state;
  final double topReserve;
  final double maxWidth;
  final Color fillColor;

  @override
  _RenderSheetLayout createRenderObject(BuildContext context) =>
      _RenderSheetLayout(
        state: state,
        topReserve: topReserve,
        maxWidth: maxWidth,
        fillColor: fillColor,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSheetLayout renderObject,
  ) {
    renderObject
      ..state = state
      ..topReserve = topReserve
      ..maxWidth = maxWidth
      ..fillColor = fillColor;
  }
}

class _RenderSheetLayout extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderSheetLayout({
    required _VaulSheetState state,
    required double topReserve,
    required double maxWidth,
    required Color fillColor,
  }) : _state = state,
       _topReserve = topReserve,
       _maxWidth = maxWidth,
       _fillColor = fillColor;

  _VaulSheetState _state;
  set state(_VaulSheetState value) {
    if (identical(value, _state)) return;
    if (attached) _state._motion.removeListener(markNeedsPaint);
    _state = value;
    if (attached) _state._motion.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  double _topReserve;
  set topReserve(double value) {
    if (value == _topReserve) return;
    _topReserve = value;
    markNeedsLayout();
  }

  double _maxWidth;
  set maxWidth(double value) {
    if (value == _maxWidth) return;
    _maxWidth = value;
    markNeedsLayout();
  }

  Color _fillColor;
  set fillColor(Color value) {
    if (value == _fillColor) return;
    _fillColor = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _state._motion.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _state._motion.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void performLayout() {
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    final available = math.max(0.0, size.height - _topReserve);
    final width = math.min(size.width, _maxWidth);
    final snaps = _state._route.snaps;
    if (snaps == null) {
      child.layout(
        BoxConstraints(minWidth: width, maxWidth: width, maxHeight: available),
        parentUsesSize: true,
      );
    } else {
      final tallest =
          resolveSnaps(snaps, available: available, content: 0).last;
      child.layout(
        BoxConstraints.tightFor(width: width, height: tallest),
        parentUsesSize: true,
      );
    }
    _state._didLayout(available, child.size.height);
  }

  /// Where the child is painted right now.
  Offset get _childOffset {
    final child = this.child;
    if (child == null) return Offset.zero;
    return Offset(
      (size.width - child.size.width) / 2,
      size.height - _state.visible,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || _state.visible <= 0) return;
    final childOffset = _childOffset;
    final bottom = childOffset.dy + child.size.height;
    if (bottom < size.height) {
      // Stretched above its tallest snap: fill the gap under it.
      context.canvas.drawRect(
        Rect.fromLTRB(
          childOffset.dx,
          bottom - 1,
          childOffset.dx + child.size.width,
          size.height,
        ).shift(offset),
        Paint()..color = _fillColor,
      );
    }
    context.paintChild(child, offset + childOffset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null || _state.visible <= 0) return false;
    return result.addWithPaintOffset(
      offset: _childOffset,
      position: position,
      hitTest:
          (result, transformed) => child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = _childOffset;
    transform.multiply(Matrix4.translationValues(offset.dx, offset.dy, 0));
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
}
