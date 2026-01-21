import 'dart:io';

import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CloudflareInterceptor extends Interceptor {
  final Dio dio;
  final Map<String, String> cookies = {};

  CloudflareInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (cookies.isNotEmpty) {
      options.headers[HttpHeaders.cookieHeader] = getCookies();
    }
    handler.next(options);
  }

  String getCookies() {
    return cookies.entries.map((e) => "${e.key}=${e.value}").join("; ");
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (_isChallenge(response)) {
      _passChallenge(response.requestOptions.uri.toString());
      handler.reject(
        CloudflareException(
          requestOptions: response.requestOptions,
          cloudflareType: .challenge,
        ),
      );
      return;
    }
    handler.next(response);
  }

  bool _isChallenge(Response<dynamic> response) {
    return response.statusCode == 403 &&
        response.headers.value("cf-mitigated") == "challenge";
  }

  Future<void> _passChallenge(String url) async {
    if (App.isDesktop) {
      _passChallengeDesktop(url);
    } else if (App.isMobile) {
      _passChallengeMobile(url);
    }
  }

  void _passChallengeDesktop(String url) async {
    WebviewWindow.closeAll();
    await Future.delayed(Duration(milliseconds: 200));
    var webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: "Cloudflare验证",
        titleBarHeight: 0,
      ),
    );
    webview.setUserAgent(dio.options.headers[HttpHeaders.userAgentHeader]);
    webview.setOnHistoryChangedCallback((canGoBack, canGoForward) async {
      var html = await webview.getHtml();
      if (html.isNotEmpty &&
          !html.contains("ray-id") &&
          !html.contains("rayId") &&
          !html.contains("Ray Id")) {
        var cookies = await webview.getAllCookies();
        var clearance = cookies
            .where(
              (cookie) => cookie.name.contains("cf_clearance"),
            )
            .firstOrNull;
        if (clearance == null) {
          return;
        }
        debugPrint("cloudflare pass!");
        String name = clearance.name.trim().replaceFirst('\u0000', '');
        var value = clearance.value.trim().replaceFirst('\u0000', '');
        this.cookies[name] = value;
        webview.close();
      }
    });
    webview.openDevToolsWindow();
    webview.launch(url);
  }

  void _passChallengeMobile(String url) async {}
}

class CloudflareException extends DioException with ExceptionWidgetMixin {
  final CloudflareExceptionType cloudflareType;

  CloudflareException({
    required super.requestOptions,
    required this.cloudflareType,
  });

  @override
  Widget buildExceptionWidget(BuildContext context, ExceptionWidget widget) {
    if (cloudflareType == CloudflareExceptionType.challenge) {
      return _buildChallenge(widget);
    } else {
      return _buildRateLimit(widget);
    }
  }

  Widget _buildChallenge(ExceptionWidget widget) {
    return ExceptionWidgetMixin.defaultWidget(
      "请在打开的页面中进行Cloudflare验证，完成后点击重试按钮",
      widget,
    );
  }

  Widget _buildRateLimit(ExceptionWidget widget) {
    return ExceptionWidgetMixin.defaultWidget(
      "请求过于频繁，请稍后再试",
      widget,
    );
  }
}

enum CloudflareExceptionType {
  challenge,
  rateLimit,
}
