import 'dart:io';

import 'package:dio/dio.dart';

class BiliNovelRedirectInterceptor extends Interceptor {
  const BiliNovelRedirectInterceptor(this.onRedirectDomain);

  final void Function(String redirectDomain)? onRedirectDomain;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 301 || response.statusCode == 302) {
      var location = response.headers[HttpHeaders.locationHeader]?.firstOrNull;
      if (location != null) {
        var redirectDomain = Uri.parse(location).host;
        onRedirectDomain?.call(redirectDomain);
      }
    }
    handler.next(response);
  }
}
