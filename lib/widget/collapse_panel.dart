import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CollapsePanel extends StatefulWidget {
  final WidgetBuilder title;
  final WidgetBuilder child;
  final bool initiallyExpanded;
  final Decoration? decoration;

  const CollapsePanel({
    super.key,
    required this.title,
    required this.child,
    this.decoration,
    this.initiallyExpanded = false,
  });

  @override
  State<StatefulWidget> createState() {
    return CollapsePanelState();
  }
}

class CollapsePanelState extends State<CollapsePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;
  bool _isExpanded = false;

  bool get expanded => _isExpanded;

  AnimationController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
    _isExpanded = widget.initiallyExpanded;
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.decoration,
      clipBehavior: widget.decoration != null ? Clip.hardEdge : Clip.none,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Column(
            children: [
              widget.title.call(context),
              ClipRect(
                child: Align(
                  alignment: .topLeft,
                  heightFactor: _heightFactor.value,
                  child: widget.child.call(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void toggle([bool? expand]) {
    setState(() {
      _isExpanded = expand ?? !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }
}
