import 'dart:io';

import 'package:dio/dio.dart';

class RedirectInterceptor extends Interceptor {
  final Dio dio;

  static const String redirectKey = "redirect";

  RedirectInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.followRedirects = false;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 301 || response.statusCode == 302) {
      var location = response.headers[HttpHeaders.locationHeader]?.firstOrNull;
      if (location != null) {
        var redirectOptions = response.requestOptions.copyWith(path: location);
        redirectOptions.extra[redirectKey] =
            redirectOptions.extra[redirectKey] as List? ?? <String>[];
        (redirectOptions.extra[redirectKey] as List<String>).add(
          response.requestOptions.uri.toString(),
        );
        dio
            .fetch(redirectOptions)
            .then((resp) => handler.next(resp))
            .catchError((e) => handler.reject(e));
        return;
      }
    }
    handler.next(response);
  }
}