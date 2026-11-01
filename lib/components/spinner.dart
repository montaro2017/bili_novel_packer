import 'dart:async';

import 'package:nocterm/nocterm.dart';

const List<String> _defaultDots = [
  '⠋',
  '⠙',
  '⠹',
  '⠸',
  '⠼',
  '⠴',
  '⠦',
  '⠧',
  '⠇',
  '⠏',
];

class Spinner extends StatefulComponent {
  Spinner({
    this.color,
    this.dots = _defaultDots,
  }) : assert(dots.isNotEmpty);

  final Color? color;
  final List<String> dots;

  @override
  State<StatefulComponent> createState() => SpinnerState();
}

class SpinnerState extends State<Spinner> {
  int index = 0;

  String get dot => component.dots[index % component.dots.length];

  void next() {
    if (!mounted) return;
    setState(() {
      index = (index + 1) % component.dots.length;
    });
  }

  @override
  void initState() {
    super.initState();
    _SpinnerClock.add(this);
  }

  @override
  void didUpdateComponent(covariant Spinner oldComponent) {
    super.didUpdateComponent(oldComponent);
    index %= component.dots.length;
  }

  @override
  void dispose() {
    _SpinnerClock.remove(this);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return Text(
      dot,
      style: TextStyle(
        color: component.color,
      ),
    );
  }
}

/// Starts with the first spinner and stops when the last one is disposed.
class _SpinnerClock {
  static const _interval = Duration(milliseconds: 166);
  static final _states = <SpinnerState>{};
  static Timer? _timer;
  static int? _frameId;

  static void add(SpinnerState state) {
    _states.add(state);
    _timer ??= Timer.periodic(_interval, _tick);
  }

  static void remove(SpinnerState state) {
    _states.remove(state);
    if (_states.isEmpty) {
      _timer?.cancel();
      _timer = null;
      if (_frameId != null) {
        SchedulerBinding.instance.cancelFrameCallbackWithId(_frameId!);
        _frameId = null;
      }
    }
  }

  static void _tick(Timer _) {
    // Coalesce ticks while a frame is already pending.
    if (_frameId != null) return;
    _frameId = SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameId = null;
      for (final state in _states.toList()) {
        state.next();
      }
    });
  }
}
