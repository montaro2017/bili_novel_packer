import 'package:nocterm/nocterm.dart';

typedef ClickableBuilder = Component Function(bool hover);

class Clickable extends StatefulComponent {
  const Clickable({
    required this.builder,
    this.onClick,
  });

  final ClickableBuilder builder;
  final void Function()? onClick;

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
        },
        onExit: (_) {
          setState(() {
            hover = false;
          });
        },
        child: component.builder.call(hover),
      ),
    );
  }
}
