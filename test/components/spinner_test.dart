import 'dart:async';

import 'package:bili_novel_packer/components/spinner.dart';
import 'package:nocterm/nocterm.dart';
import 'package:test/test.dart';

void main() {
  test(
    'spinners share a timer and release it after the last unmount',
    () async {
      final timers = <Timer>[];
      late void Function(Timer) tick;
      await runZoned(
        () async {
          final tester = await NoctermTester.create();
          try {
            await tester.pumpComponent(_SpinnerHost());
            final host = tester.findState<_SpinnerHostState>();
            expect(timers, hasLength(1));
            expect(tester.renderToString(), contains('aa'));

            tick(timers.single);
            tick(timers.single); // Both ticks should coalesce into one frame.
            await tester.pump();
            expect(tester.renderToString(), contains('bb'));

            host.update(count: 1);
            await tester.pump();
            expect(timers.single.isActive, isTrue);
            final previousDot = tester.findState<SpinnerState>().dot;
            tick(timers.single);
            await tester.pump();
            expect(tester.findState<SpinnerState>().dot, isNot(previousDot));

            tick(timers.single); // Unmount before the queued frame runs.
            host.update(count: 0);
            await tester.pump();
            expect(timers.single.isActive, isFalse);

            host.update(count: 1);
            await tester.pump();
            expect(timers, hasLength(2));
            tick(timers.last);
            await tester.pump();
            expect(tester.findState<SpinnerState>().dot, 'b');
            host.update(dots: ['x']);
            await tester.pump();
            expect(tester.findState<SpinnerState>().dot, 'x');
            host.update(count: 0);
            await tester.pump();
            expect(timers.last.isActive, isFalse);
          } finally {
            tester.dispose();
            for (final timer in timers) {
              timer.cancel();
            }
          }
        },
        zoneSpecification: ZoneSpecification(
          createPeriodicTimer: (self, parent, zone, duration, callback) {
            expect(duration, const Duration(milliseconds: 166));
            tick = callback;
            // Drive ticks manually so the test does not depend on wall time.
            final timer = parent.createPeriodicTimer(
              zone,
              const Duration(days: 1),
              callback,
            );
            timers.add(timer);
            return timer;
          },
        ),
      );
    },
  );
}

class _SpinnerHost extends StatefulComponent {
  @override
  State<_SpinnerHost> createState() => _SpinnerHostState();
}

class _SpinnerHostState extends State<_SpinnerHost> {
  int count = 2;
  List<String> dots = ['a', 'b'];

  void update({int? count, List<String>? dots}) {
    setState(() {
      this.count = count ?? this.count;
      this.dots = dots ?? this.dots;
    });
  }

  @override
  Component build(BuildContext context) => Row(
    children: List.generate(count, (_) => Spinner(dots: dots)),
  );
}
