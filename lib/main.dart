import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/pages/home/home_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  if (runWebViewTitleBarWidget(args)) {
    return;
  }
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
    FlutterDisplayMode.setHighRefreshRate().catchError((e) {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: App.navigatorKey,
      title: 'Flutter Demo',
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        fontFamily: "MiSans",
        fontFamilyFallback: [
          // 'MiSans',
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
