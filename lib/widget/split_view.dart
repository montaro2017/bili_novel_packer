import 'package:flutter/material.dart';

typedef SplitPanelBuilder =
    Widget Function(BuildContext ctx, SplitViewLayout status);

enum SplitViewLayout { all, left, right }

class SplitView extends StatefulWidget {
  final SplitViewController? controller;

  /// 左侧组件A
  final SplitPanelBuilder leftBuilder;

  /// 右侧组件B
  final SplitPanelBuilder rightBuilder;

  final SplitViewLayout layout;

  /// 并排时左侧组件的约束
  final BoxConstraints? leftConstraints;

  /// 并排时间隔宽度
  final double dividerWidth;

  const SplitView({
    super.key,
    required this.leftBuilder,
    required this.rightBuilder,
    this.controller,
    this.layout = .all,
    this.leftConstraints,
    this.dividerWidth = 1.0,
  });

  @override
  State<StatefulWidget> createState() => _SplitViewState();
}

class _SplitViewState extends State<SplitView> {
  late SplitViewController _controller;
  late SplitViewLayout _layout;

  @override
  void initState() {
    super.initState();
    _layout = widget.layout;
    _controller = widget.controller ?? SplitViewController();
    _controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant SplitView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_layout != oldWidget.layout) {
      setState(() {
        _layout = widget.layout;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var leftPanel = _leftPanel();
    var rightPanel = _rightPanel();
    Widget child;
    if (_layout == .all) {
      child = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftPanel,
          VerticalDivider(width: widget.dividerWidth),
          rightPanel,
        ],
      );
    } else {
      child = _buildStackLayout(leftPanel, rightPanel);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_layout == .all || _layout == .left) {
            Navigator.maybePop(context);
          } else if (_layout == .right) {
            _backToLeft();
          }
        }
      },
      child: child,
    );
  }

  Widget _leftPanel() {
    var leftPanel = widget.leftBuilder(context, _layout);
    if (_layout == .all) {
      if (widget.leftConstraints != null) {
        leftPanel = ConstrainedBox(
          constraints: widget.leftConstraints!,
          child: leftPanel,
        );
      } else {
        leftPanel = Expanded(child: leftPanel);
      }
    }
    return leftPanel;
  }

  Widget _rightPanel() {
    var rightPanel = widget.rightBuilder(context, _layout);
    if (_layout == .all) {
      rightPanel = Expanded(child: rightPanel);
    }
    return rightPanel;
  }

  Widget _buildStackLayout(Widget leftPanel, Widget rightPanel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return Stack(
          children: [
            // Left panel - always fills the screen
            Positioned.fill(child: leftPanel),
            // Right panel - animated position based on layout
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _layout == .right ? 0 : screenWidth,
              top: 0,
              bottom: 0,
              width: screenWidth,
              child: rightPanel,
            ),
          ],
        );
      },
    );
  }

  void _onChange() {
    setState(() {
      _layout = _controller.layout;
    });
  }

  void _backToLeft() {}
}

class SplitViewController extends ChangeNotifier {
  SplitViewLayout _layout;

  SplitViewLayout get layout => _layout;

  SplitViewController([this._layout = SplitViewLayout.all]);

  void showAll() {
    if (_layout != .all) {
      _layout = .all;
      notifyListeners();
    }
  }

  void switchToRight() {
    if (_layout != .right) {
      _layout = .right;
      notifyListeners();
    }
  }

  void backToLeft() {
    if (_layout != .left) {
      _layout = .left;
      notifyListeners();
    }
  }
}
