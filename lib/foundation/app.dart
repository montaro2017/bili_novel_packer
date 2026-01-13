import 'package:flutter/widgets.dart';

class App {

  static BreakPoint breakPoint(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    for (var breakPoint in BreakPoint.values) {
      if(width <= breakPoint.max) {
        return breakPoint;
      }
    }
    return BreakPoint.xxl;
  }

}

enum BreakPoint implements Comparable<BreakPoint> {
  xs(575),
  sm(767),
  md(991),
  lg(1199),
  xl(1399),
  xxl(65535);

  final double max;

  const BreakPoint(this.max);

  @override
  int compareTo(BreakPoint other) {
    return max.compareTo(other.max);
  }

  bool operator > (BreakPoint other) {
    return max > other.max;
  }

  bool operator >= (BreakPoint other) {
    return max >= other.max;
  }

  bool operator < (BreakPoint other) {
    return max < other.max;
  }

  bool operator <= (BreakPoint other) {
    return max <= other.max;
  }

}
