import 'dart:math' as math;

import 'package:nocterm/nocterm.dart';
// TerminalCanvas 未从公开 API 导出，渲染子项需要该类型。
// ignore: implementation_imports
import 'package:nocterm/src/framework/terminal_canvas.dart';

/// 每行（run）内子项沿主轴的对齐方式。
enum WrapAlignment {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

/// 每行内子项沿交叉轴（垂直）的对齐方式。
enum WrapCrossAxisAlignment { start, end, center }

class WrapParentData extends BoxParentData {}

/// 流式布局：子项沿水平方向依次排列，超出可用宽度时换到下一行。
///
/// 类似 Flutter 的 [Wrap]（仅支持水平方向），用于需要自动换行且保留子项交互的场景。
class Wrap extends RenderObjectComponent {
  const Wrap({
    super.key,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAxisAlignment.start,
    this.children = const [],
  });

  /// 同一行内相邻子项的水平间距。
  final double spacing;

  /// 相邻两行之间的垂直间距。
  final double runSpacing;

  /// 每行内子项沿主轴的对齐方式。
  final WrapAlignment alignment;

  /// 每行内子项沿交叉轴（垂直）的对齐方式。
  final WrapCrossAxisAlignment crossAxisAlignment;

  final List<Component> children;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderWrap(
        spacing: spacing,
        runSpacing: runSpacing,
        alignment: alignment,
        crossAxisAlignment: crossAxisAlignment,
      );

  @override
  void updateRenderObject(BuildContext context, RenderWrap renderObject) {
    renderObject
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..alignment = alignment
      ..crossAxisAlignment = crossAxisAlignment;
  }

  @override
  MultiChildRenderObjectElement createElement() =>
      MultiChildRenderObjectElement(this);
}

class RenderWrap extends RenderObject
    with ContainerRenderObjectMixin<RenderObject> {
  RenderWrap({
    required double spacing,
    required double runSpacing,
    required WrapAlignment alignment,
    required WrapCrossAxisAlignment crossAxisAlignment,
  })  : _spacing = spacing,
        _runSpacing = runSpacing,
        _alignment = alignment,
        _crossAxisAlignment = crossAxisAlignment;

  double _spacing;
  double get spacing => _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _runSpacing;
  double get runSpacing => _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  WrapAlignment _alignment;
  WrapAlignment get alignment => _alignment;
  set alignment(WrapAlignment value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  WrapCrossAxisAlignment _crossAxisAlignment;
  WrapCrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  set crossAxisAlignment(WrapCrossAxisAlignment value) {
    if (_crossAxisAlignment == value) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! WrapParentData) {
      child.parentData = WrapParentData();
    }
  }

  @override
  void performLayout() {
    if (children.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final double maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : double.infinity;

    // 先以宽松约束布局所有子项，得到各自自然尺寸。
    final BoxConstraints childConstraints = BoxConstraints(
      minWidth: 0,
      maxWidth: maxWidth,
      minHeight: 0,
      maxHeight: constraints.maxHeight,
    );
    for (final child in children) {
      child.layout(childConstraints, parentUsesSize: true);
    }

    // 按宽度分装成多行。
    final List<List<RenderObject>> runs = <List<RenderObject>>[];
    List<RenderObject> run = <RenderObject>[];
    double runWidth = 0;
    for (final child in children) {
      final double w = child.size.width;
      final double needed = run.isEmpty ? w : runWidth + _spacing + w;
      if (run.isNotEmpty && maxWidth.isFinite && needed > maxWidth) {
        runs.add(run);
        run = <RenderObject>[];
        runWidth = 0;
      }
      runWidth = run.isEmpty ? w : runWidth + _spacing + w;
      run.add(child);
    }
    if (run.isNotEmpty) runs.add(run);

    // 计算每行宽高与总高度。
    final List<double> runHeights = <double>[];
    final List<double> runWidths = <double>[];
    double totalHeight = 0;
    for (final List<RenderObject> run in runs) {
      double rh = 0;
      double rw = 0;
      for (final child in run) {
        rh = math.max(rh, child.size.height);
        rw += child.size.width;
      }
      rw += _spacing * (run.length - 1);
      runHeights.add(rh);
      runWidths.add(rw);
      totalHeight += rh;
    }
    totalHeight += _runSpacing * (runs.length - 1);

    // 宽度：有界时撑满，无界时收缩到最宽一行。
    final double width = maxWidth.isFinite
        ? maxWidth
        : runWidths.fold(0.0, math.max);
    size = constraints.constrain(Size(width, totalHeight));

    // 定位子项。
    double y = 0;
    for (int i = 0; i < runs.length; i++) {
      final List<RenderObject> run = runs[i];
      final double rh = runHeights[i];
      final double rw = runWidths[i];
      final double freeX = math.max(0.0, width - rw);

      double x = 0;
      double betweenSpace = 0;
      switch (_alignment) {
        case WrapAlignment.start:
          break;
        case WrapAlignment.end:
          x = freeX;
          break;
        case WrapAlignment.center:
          x = freeX / 2;
          break;
        case WrapAlignment.spaceBetween:
          betweenSpace = run.length > 1 ? freeX / (run.length - 1) : 0;
          break;
        case WrapAlignment.spaceAround:
          betweenSpace = run.isNotEmpty ? freeX / run.length : 0;
          x = betweenSpace / 2;
          break;
        case WrapAlignment.spaceEvenly:
          betweenSpace = run.isNotEmpty ? freeX / (run.length + 1) : 0;
          x = betweenSpace;
          break;
      }

      for (final child in run) {
        final WrapParentData pd = child.parentData as WrapParentData;
        double childY = 0;
        switch (_crossAxisAlignment) {
          case WrapCrossAxisAlignment.start:
            break;
          case WrapCrossAxisAlignment.end:
            childY = rh - child.size.height;
            break;
          case WrapCrossAxisAlignment.center:
            childY = (rh - child.size.height) / 2;
            break;
        }
        pd.offset = Offset(x, y + childY);
        x += child.size.width + _spacing + betweenSpace;
      }

      y += rh + _runSpacing;
    }
  }

  @override
  void paint(TerminalCanvas canvas, Offset offset) {
    super.paint(canvas, offset);
    for (final child in children) {
      final WrapParentData pd = child.parentData as WrapParentData;
      child.paintWithContext(canvas, offset + pd.offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    for (final child in children.reversed) {
      final WrapParentData pd = child.parentData as WrapParentData;
      if (child.hitTest(result, position: position - pd.offset)) {
        return true;
      }
    }
    return false;
  }
}
