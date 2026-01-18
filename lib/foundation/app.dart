import 'dart:io';

import 'package:flutter/widgets.dart';

class App {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get globalContext => navigatorKey.currentContext;

  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static BreakPoint breakPoint(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    for (var breakPoint in BreakPoint.values) {
      if (width <= breakPoint.max) {
        return breakPoint;
      }
    }
    return BreakPoint.xxl;
  }

  void navigateTo<T>(Route<T> route) {
    Navigator.of(globalContext!).push(route);
  }
}

enum BreakPoint implements Comparable<BreakPoint> {
  xs(575),
  sm(767),
  md(991),
  lg(1199),
  xl(1399),
  xxl(65535)
  ;

  final double max;

  const BreakPoint(this.max);

  @override
  int compareTo(BreakPoint other) {
    return max.compareTo(other.max);
  }

  bool operator >(BreakPoint other) {
    return max > other.max;
  }

  bool operator >=(BreakPoint other) {
    return max >= other.max;
  }

  bool operator <(BreakPoint other) {
    return max < other.max;
  }

  bool operator <=(BreakPoint other) {
    return max <= other.max;
  }
}
