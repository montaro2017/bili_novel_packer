import 'package:nocterm/nocterm.dart';

typedef ClickableBuilder = Component Function(bool hover);

class Clickable extends StatefulComponent {
  const Clickable({
    required this.builder,
    this.onClick,
    this.onEnter,
    this.onExit,
  });

  final ClickableBuilder builder;
  final void Function()? onClick;
  final void Function()? onEnter;
  final void Function()? onExit;

  @override
  State<StatefulComponent> createState() => _ClickableState();
}

class _ClickableState extends State<Clickable> {
  bool hover = false;

  @override
  Component build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        component.onClick?.call();
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            hover = true;
          });
          component.onEnter?.call();
        },
        onExit: (_) {
          setState(() {
            hover = false;
          });
          component.onExit?.call();
        },
        child: component.builder.call(hover),
      ),
    );
  }
}
