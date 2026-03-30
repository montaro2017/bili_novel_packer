import 'package:bili_novel_packer/novel_source/base/base_webview_interceptor.dart';
import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class CloudflareInterceptor extends BaseWebviewInterceptor {
  static const String cfClearance = "cf_clearance";

  CloudflareInterceptor(Dio dio, [Set<String>? cookieNames])
    : super(
        dio,
        cookieNames == null ? {cfClearance} : {...cookieNames, cfClearance},
      );

  bool isChallenge(Response<dynamic> response) {
    return response.statusCode == 403 &&
        response.headers.value("cf-mitigated") == "challenge";
  }

  bool isReteLimit(Response<dynamic> response) {
    return false;
  }

  @override
  bool shouldOpenWebview(Response<dynamic> response) {
    return isChallenge(response);
  }

  @override
  String getWebviewTitle(Response<dynamic> response) {
    return "请完成Cloudflare验证";
  }

  @override
  bool isResolved(String html, Map<String, String> cookies) {
    return super.isResolved(html, cookies) &&
        !html.contains("window._cf_chl_opt");
  }

  @override
  DioException getClosedException(response) {
    if (isReteLimit(response)) {
      return CloudflareException(
        requestOptions: response.requestOptions,
        cloudflareType: CloudflareExceptionType.rateLimit,
      );
    }
    return CloudflareException(
      requestOptions: response.requestOptions,
      cloudflareType: CloudflareExceptionType.challenge,
    );
  }
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
      widget.retry,
    );
  }

  Widget _buildRateLimit(ExceptionWidget widget) {
    return ExceptionWidgetMixin.defaultWidget(
      "请求过于频繁，请稍后再试",
      widget.retry,
    );
  }
}

enum CloudflareExceptionType {
  challenge,
  rateLimit,
}
