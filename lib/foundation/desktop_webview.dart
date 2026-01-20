import 'dart:async';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/cupertino.dart';

class DesktopWebview {
  final String? userAgent;
  bool _cloudflare = false;
  void Function()? cloudflarePassCallback;
  late Webview? webview;
  bool _keepForeground = false;
  bool _initialized = false;

  static Future<bool> get isAvailable => WebviewWindow.isWebviewAvailable();

  DesktopWebview({this.userAgent, this.cloudflarePassCallback});

  Future<void> init({CreateConfiguration? configuration}) async {
    if (_initialized) {
      webview?.close();
      webview = null;
    }
    _initialized = true;
    webview = await WebviewWindow.create(configuration: configuration);
    if (userAgent != null && userAgent!.isNotEmpty) {
      webview?.setUserAgent(userAgent!);
    }
    var timer = Timer.periodic(Duration(milliseconds: 300), (_) async {
      try {
        if (_keepForeground) {
          webview?.bringToForeground();
        }
        var html = await getHtml();
        if (html != null && html.isNotEmpty && html.length > 100) {
          if (html.contains("ray-id")) {
            _cloudflare = true;
          }
          if (!html.contains("ray-id")) {
            if (_cloudflare) {
              cloudflarePassCallback?.call();
            }
            _cloudflare = false;
          }
        }
      } catch (_) {
        // ignore
      }
    });
    // Future.delayed(Duration(seconds: 1)).then((_) async {
    //   var html = await getHtml();
    //   if (html != null && html.length > 100 && !html.contains("ray-id")) {
    //     cloudflarePassCallback?.call();
    //   }
    // });
    webview?.onClose.whenComplete(() {
      timer.cancel();
    });
  }

  void launch(String url) {
    webview?.launch(url);
  }

  void keepForeground([bool keep = true]) {
    _keepForeground = keep;
  }

  void close() {
    webview?.close();
    webview = null;
  }

  void clearAll() {
    WebviewWindow.clearAll();
  }

  Future<List<WebviewCookie>?> getAllCookies() async {
    return webview?.getAllCookies();
  }

  Future<WebviewCookie?> getCookie(
    bool Function(WebviewCookie) predicate,
  ) async {
    return getAllCookies().then((cookies) {
      for (var cookie in cookies ?? []) {
        if (predicate(cookie)) {
          return cookie;
        }
      }
      return null;
    });
  }

  Future<String?> getHtml() async {
    return await webview?.evaluateJavaScript(
      'document.querySelector("html").outerHTML',
    );
  }

  void openDevTools() async {
    await webview?.openDevToolsWindow();
  }
}
