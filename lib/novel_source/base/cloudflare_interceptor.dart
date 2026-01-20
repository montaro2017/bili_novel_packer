import 'dart:io';

import 'package:bili_novel_packer/foundation/app.dart';
import 'package:bili_novel_packer/foundation/desktop_webview.dart';
import 'package:dio/dio.dart';

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
    handler.resolve(response);
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
    var cloudflarePass = false;
    var webview = DesktopWebview(
      userAgent: dio.options.headers[HttpHeaders.userAgentHeader],
      cloudflarePassCallback: () {
        cloudflarePass = true;
      },
    );
    await webview.init();
    webview.launch(url);
    while (!cloudflarePass) {
      await Future.delayed(Duration(milliseconds: 50));
    }
    var cookie = await webview.getCookie(
      (cookie) => cookie.name.contains("cf_clearance"),
    );
    if (cookie == null) {
      return;
    }
    var name = cookie.name.trim().replaceFirst('\u0000', '');
    var value = cookie.value.trim().replaceFirst('\u0000', '');
    cookies[name] = value;
    webview.close();
  }

  void _passChallengeMobile(String url) async {}
}

class CloudflareException extends DioException {
  final CloudflareExceptionType cloudflareType;

  CloudflareException({
    required super.requestOptions,
    required this.cloudflareType,
  });
}

enum CloudflareExceptionType {
  challenge,
  rateLimit,
}
