import 'dart:io';

import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dio/dio.dart';

class CloudflareInterceptor extends Interceptor {
  final Dio dio;
  final NovelSource source;

  CloudflareInterceptor(this.dio, this.source);

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_isChallenge(response)) {
      await _passChallenge(response.requestOptions.uri.toString());
    }
    handler.resolve(response);
  }

  bool _isChallenge(Response<dynamic> response) {
    return response.statusCode == 403 &&
        response.headers.value("cf-mitigated") == "challenge";
  }

  Future<void> _passChallenge(String url) async {
    if (App.isDesktop) {
      if (await WebviewWindow.isWebviewAvailable()) {
        await _desktopWebview(url);
      }
    }
  }

  Future<void> _desktopWebview(String url) async {
    print(url);
    var webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        windowWidth: 430,
        windowHeight: 932,
        title: "Cloudflare验证",
        useWindowPositionAndSize: true,
        // titleBarHeight: 0,
        titleBarTopPadding: Platform.isMacOS ? 20 : 0,
      ),
    );
    webview.setUserAgent(source.userAgent);
    webview.launch(url);
  }

  void _mobileWebview(String url) {}
}
