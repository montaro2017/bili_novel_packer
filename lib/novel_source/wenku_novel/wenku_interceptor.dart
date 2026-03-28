import 'package:bili_novel_packer/novel_source/base/cloudflare_interceptor.dart';
import 'package:bili_novel_packer/novel_source/base/redirect_interceptor.dart';
import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class WenkuInterceptor extends CloudflareInterceptor {
  WenkuInterceptor(Dio dio) : super(dio, {"PHPSESSID"});

  bool _isLogin(Response<dynamic> response) {
    return response.requestOptions.uri.path == '/login.php';
  }

  @override
  bool shouldOpenWebview(Response<dynamic> response) {
    return super.shouldOpenWebview(response) || _isLogin(response);
  }

  @override
  String getWebviewUrl(Response<dynamic> response) {
    if (_isLogin(response)) {
      return response.requestOptions.extra[RedirectInterceptor.redirectKey]!
          .cast<String>()!
          .first;
    }
    return super.getWebviewUrl(response);
  }

  @override
  String getWebviewTitle(Response<dynamic> response) {
    if (_isLogin(response)) {
      return "请先登录";
    }
    return super.getWebviewTitle(response);
  }

  @override
  DioException getClosedException(response) {
    if (_isLogin(response)) {
      return WenkuLoginException(requestOptions: response.requestOptions);
    }
    return super.getClosedException(response);
  }
}

class WenkuLoginException extends DioException with ExceptionWidgetMixin {
  WenkuLoginException({required super.requestOptions});

  @override
  Widget buildExceptionWidget(BuildContext context, ExceptionWidget widget) {
    return ExceptionWidgetMixin.defaultWidget(
      "账号未登录",
      widget.retry,
    );
  }
}
