import 'package:flutter/material.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DownloadPageState();
  }
}

class _DownloadPageState extends State<DownloadPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Center(
        child: Text("下载"),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
