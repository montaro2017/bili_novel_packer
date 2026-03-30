import 'dart:io';

import 'package:bili_novel_packer/foundation/app.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

abstract class BaseWebviewInterceptor extends QueuedInterceptor {
  late final Dio _dio;
  final Set<String> cookieNames;
  final Map<String, String> _cookies = {};

  BaseWebviewInterceptor(Dio dio, this.cookieNames) {
    _dio = dio.clone();
  }

  void addCookie(String name, String value) {
    _cookies[name] = value;
  }

  String get cookies {
    return _cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_cookies.isNotEmpty) {
      options.headers[HttpHeaders.cookieHeader] = cookies;
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (shouldOpenWebview(response)) {
      String webviewUrl = getWebviewUrl(response);
      String webviewTitle = getWebviewTitle(response);
      _openWebview(webviewUrl, webviewTitle, response, handler);
      return;
    }
    super.onResponse(response, handler);
  }

  bool shouldOpenWebview(Response<dynamic> response);

  String getWebviewUrl(Response<dynamic> response) {
    return response.requestOptions.uri.toString();
  }

  String getWebviewTitle(Response<dynamic> response);

  bool isResolved(String html, Map<String, String> cookies) {
    return cookieNames.every(
      (cookieName) => cookies.containsKey(cookieName),
    );
  }

  DioException getClosedException(Response<dynamic> response);

  void _openWebview(
    String url,
    String title,
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (App.isDesktop) {
      _openWebViewDesktop(url, title, response, handler);
    } else if (App.isMobile) {
      _openWebviewMobile(url, title, response, handler);
    }
  }

  void _openWebViewDesktop(
    String url,
    String title,
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    debugPrint("open webview url: $url");
    WebviewWindow.closeAll();
    await Future.delayed(Duration(milliseconds: 500));
    await WebviewWindow.clearAll();
    var webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: title,
      ),
    );
    var options = response.requestOptions;
    webview.setUserAgent(_dio.options.headers[HttpHeaders.userAgentHeader]);
    webview.setOnHistoryChangedCallback((canGoBack, canGoForward) async {
      String? currentUrl = await webview.evaluateJavaScript("location.href");
      debugPrint("url: $currentUrl");
      _tryResolve(webview, url, options, handler);
    });
    webview.setBeforeCloseCallback(() async {
      try {
        await _tryResolve(
          webview,
          url,
          options,
          handler,
          getClosedException(response),
        );
      } catch (e) {
        if (!handler.isCompleted) {
          handler.reject(
            DioException(requestOptions: options, message: e.toString()),
          );
        }
      }
      return true;
    });
    webview.launch(url);
  }

  Future<Map<String, String>> _getCookieFromWebview(Webview webview) async {
    var allCookies = await webview.getAllCookies();
    return Map.fromEntries(
      allCookies
          .where((cookie) => cookieNames.contains(_sanitize(cookie.name)))
          .map(
            (cookie) =>
                MapEntry(_sanitize(cookie.name), _sanitize(cookie.value)),
          ),
    );
  }

  Future<void> _tryResolve(
    Webview webview,
    String url,
    RequestOptions options,
    ResponseInterceptorHandler handler, [
    DioException? e,
  ]) async {
    if (handler.isCompleted) {
      return;
    }
    var html = await webview.getHtml();
    debugPrint(html);
    var neededCookies = await _getCookieFromWebview(webview);
    _cookies.addAll(neededCookies);
    if (!isResolved(html, neededCookies)) {
      if (e != null) {
        handler.reject(e);
      }
      return;
    }
    _cookies.addAll(neededCookies);
    var retryOptions = options.copyWith(path: url);
    retryOptions.headers[HttpHeaders.cookieHeader] = cookies;
    var response = await _dio.fetch(retryOptions);
    if (handler.isCompleted) {
      return;
    }
    handler.resolve(response);
    webview.close();
  }

  String _sanitize(String value) {
    value = value.trim();
    value = value.replaceFirst('\u0000', '');
    return value;
  }

  void _openWebviewMobile(
    String url,
    String title,
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        message: "mobile is not support",
      ),
    );
  }
}
