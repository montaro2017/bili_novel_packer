import 'dart:async';

import 'package:nocterm/nocterm.dart';
// TerminalCanvas 未从公开 API 导出，渲染子项需要该类型。
// ignore: implementation_imports
import 'package:nocterm/src/framework/terminal_canvas.dart';

/// 水平跑马灯：子项超出可用宽度时循环滚动，超出部分被裁剪。
///
/// [direction] 仅水平方向生效，传 [Axis.vertical] 时不滚动、仅静态裁剪。
class Marquee extends StatefulComponent {
  Marquee({
    super.key,
    required this.child,
    this.marquee = true,
    this.direction = Axis.horizontal,
    this.speed = 3.0,
    this.gap = 2,
  });

  /// 被滚动的子组件。
  final Component child;

  /// 开关：false 时静止显示（超出仍裁剪，不滚动）。
  final bool marquee;

  /// 滚动方向，当前仅水平方向生效。
  final Axis direction;

  /// 滚动速度，单位：单元格/秒。
  final double speed;

  /// 循环首尾之间的分隔空格数。
  final int gap;

  @override
  State<StatefulComponent> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> {
  static const Duration _interval = Duration(milliseconds: 100);

  double _offset = 0;
  Timer? _timer;
  int? _frameId;

  bool get _active =>
      component.marquee && component.direction == Axis.horizontal;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateComponent(covariant Marquee oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!_active) {
      _offset = 0;
    }
    _syncTimer();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _syncTimer() {
    if (_active) {
      _timer ??= Timer.periodic(_interval, _tick);
    } else {
      _stopTimer();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (_frameId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_frameId!);
      _frameId = null;
    }
  }

  void _tick(Timer _) {
    // 与 Spinner 相同：把定时器 tick 合并到同一帧，避免每 tick 重排一次。
    if (_frameId != null) return;
    _frameId = SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameId = null;
      if (!mounted) return;
      setState(() {
        _offset += component.speed * _interval.inMilliseconds / 1000;
      });
    });
  }

  @override
  Component build(BuildContext context) {
    return _MarqueeViewport(
      child: component.child,
      enabled: _active,
      offset: _offset,
      gap: component.gap,
    );
  }
}

class _MarqueeViewport extends SingleChildRenderObjectComponent {
  const _MarqueeViewport({
    required super.child,
    required this.enabled,
    required this.offset,
    required this.gap,
  });

  final bool enabled;
  final double offset;
  final int gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMarqueeViewport(enabled: enabled, offset: offset, gap: gap);

  @override
  void updateRenderObject(
      BuildContext context, _RenderMarqueeViewport renderObject) {
    renderObject
      ..enabled = enabled
      ..offset = offset
      ..gap = gap;
  }
}

class _RenderMarqueeViewport extends RenderObject
    with RenderObjectWithChildMixin<RenderObject> {
  _RenderMarqueeViewport({
    required bool enabled,
    required double offset,
    required int gap,
  })  : _enabled = enabled,
        _offset = offset,
        _gap = gap;

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    markNeedsPaint();
  }

  double _offset;
  double get offset => _offset;
  set offset(double value) {
    if (_offset == value) return;
    _offset = value;
    markNeedsPaint();
  }

  int _gap;
  int get gap => _gap;
  set gap(int value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      // 子项以自然宽度布局（水平不设上限），垂直受父约束。
      child!.layout(
        BoxConstraints(
          minWidth: 0,
          maxWidth: double.infinity,
          minHeight: 0,
          maxHeight: constraints.maxHeight,
        ),
        parentUsesSize: true,
      );
    }
    // 宽度：收缩到子项宽度，但不超过可用宽度（内容超出时才有滚动空间）。
    final double childW = child?.size.width ?? 0;
    final double width = constraints.maxWidth.isFinite
        ? childW.clamp(0.0, constraints.maxWidth)
        : childW;
    size = constraints.constrain(Size(width, child?.size.height ?? 0));
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    if (child == null) return;

    final int viewportWidth = size.width.floor();
    final int viewportHeight = size.height.floor();
    final int childWidth = child!.size.width.floor();
    final int childHeight = child!.size.height.floor();
    if (viewportWidth <= 0 || viewportHeight <= 0 || childWidth <= 0) return;

    final clippedCanvas = canvas.clip(
      Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
    );

    // 静态或内容不超出：直接绘制（drawText 会在右缘裁剪）。
    if (!_enabled || childWidth <= viewportWidth) {
      child!.paintWithContext(clippedCanvas, Offset.zero);
      return;
    }

    // 滚动：nocterm 的 drawText 不接受负起始坐标，无法直接画部分超出左侧的内容。
    // 因此先把子项渲染到离屏 buffer，再逐格拷贝可见窗口（按子项宽度取模实现无缝循环）。
    final int offHeight = childHeight > 0 ? childHeight : 1;
    final int loopWidth = childWidth + _gap;
    final Buffer offscreen = Buffer(loopWidth, offHeight);
    final TerminalCanvas offCanvas = TerminalCanvas(
      offscreen,
      Rect.fromLTWH(0, 0, loopWidth.toDouble(), offHeight.toDouble()),
    );
    child!.paintWithContext(offCanvas, Offset.zero);

    final int o = _offset.floor() % loopWidth;
    final int rows = viewportHeight < offHeight ? viewportHeight : offHeight;
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < viewportWidth; x++) {
        final Cell cell = offscreen.getCell((o + x) % loopWidth, y);
        if (cell.char == '\u200B' || cell.isImagePlaceholder) continue;
        clippedCanvas.drawText(
          Offset(x.toDouble(), y.toDouble()),
          cell.char,
          style: cell.style,
        );
      }
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    if (child != null) {
      return child!.hitTest(result, position: position);
    }
    return false;
  }
}
