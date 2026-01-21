import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class WenkuInterceptor extends Interceptor {
  final Dio dio;

  WenkuInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (response.requestOptions.uri.path == '/login.php') {
      handler.reject(
        WenkuLoginException(requestOptions: response.requestOptions),
      );
      return;
    }
    super.onResponse(response, handler);
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
