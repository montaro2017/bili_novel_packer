import 'package:nocterm/nocterm.dart';

class Marquee extends StatefulComponent {
  Marquee({
    required this.child,
    this.marquee = true,
    this.direction = Axis.horizontal,
  });

  final Component child;
  final bool marquee;
  final Axis direction;

  @override
  State<StatefulComponent> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> {
  @override
  Component build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
