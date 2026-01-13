import 'package:bili_novel_packer/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    try {
      FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        fontFamily: "MiSans",
        fontFamilyFallback: [
          'MiSans',
          'Helvetica Neue',
          'PingFang SC',
          'Source Han Sans SC',
          'Noto Sans CJK SC',
        ],
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
