import 'dart:io';

import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/novel_source/base/redirect_interceptor.dart';
import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class WenkuInterceptor extends Interceptor {
  final Dio dio;
  final Map<String, String> cookies = {};

  WenkuInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (cookies.isNotEmpty) {
      options.headers[HttpHeaders.cookieHeader] = cookies.entries
          .map((e) => "${e.key}=${e.value}")
          .join("; ");
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (response.requestOptions.uri.path == '/login.php') {
      var url = response.requestOptions.extra[RedirectInterceptor.redirectKey]!
          .cast<String>()!
          .first;
      debugPrint("url: $url");
      _doLogin(url);
      handler.reject(
        WenkuLoginException(requestOptions: response.requestOptions),
      );
      return;
    }
    super.onResponse(response, handler);
  }

  void _doLogin(String url) async {
    if (App.isDesktop) {
      _doPcLogin(url);
    } else if (App.isMobile) {}
  }

  void _doPcLogin(String url) async {
    WebviewWindow.closeAll();
    await Future.delayed(Duration(milliseconds: 200));
    var webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: "登录轻小说文库",
        titleBarHeight: 0,
      ),
    );
    webview.setUserAgent(dio.options.headers[HttpHeaders.userAgentHeader]);
    webview.setOnHistoryChangedCallback((canGoBack, canGoForward) async {
      var cookies = (await webview.getAllCookies())
          .where(
            (cookie) =>
                cookie.name.contains("PHPSESSID") ||
                cookie.name.contains("cf_clearance"),
          )
          .toList();
      if (cookies.isEmpty) {
        return;
      }
      for (var cookie in cookies) {
        var name = cookie.name.trim().replaceFirst('\u0000', '');
        var value = cookie.value.trim().replaceFirst('\u0000', '');
        this.cookies[name] = value;
      }
      // webview.close();
    });
    webview.openDevToolsWindow();
    webview.launch(url);
  }
}

class WenkuLoginException extends DioException with ExceptionWidgetMixin {
  WenkuLoginException({required super.requestOptions});

  @override
  Widget buildExceptionWidget(BuildContext context, ExceptionWidget widget) {
    return ExceptionWidgetMixin.defaultWidget(
      "请先在打开的页面中登录，完成后点击重试按钮",
      widget,
    );
  }
}
