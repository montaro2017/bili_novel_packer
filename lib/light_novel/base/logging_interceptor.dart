import 'dart:async';

import 'package:dio/dio.dart';

typedef LogPrinter = void Function(Object? message);

enum LoggingInterceptorLevel {
  none,
  basic,
  headers,
  body,
}

class LoggingInterceptor extends Interceptor {
  static const String _startTimeKey = "logging_interceptor_start_time";

  LoggingInterceptorLevel level;
  final LogPrinter printer;

  LoggingInterceptor({
    this.level = LoggingInterceptorLevel.basic,
    LogPrinter? printer,
  }) : printer = printer ?? print;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (level == LoggingInterceptorLevel.none) {
      handler.next(options);
      return;
    }

    options.extra[_startTimeKey] = DateTime.now();

    bool logHeaders = _logHeaders;
    bool logBody = _logBody;
    Uri uri = options.uri;

    _log("--> ${options.method} $uri");

    if (logHeaders) {
      if (options.contentType != null) {
        _log("${Headers.contentTypeHeader}: ${options.contentType}");
      }
      options.headers.forEach((key, value) => _log("$key: $value"));

      if (logBody && options.data != null) {
        _log("");
        _log(_formatBody(options.data));
      }
    }

    _log("--> END ${options.method}");
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (level == LoggingInterceptorLevel.none) {
      handler.next(response);
      return;
    }

    RequestOptions options = response.requestOptions;
    Duration duration = _duration(options);
    int? statusCode = response.statusCode;
    String statusMessage = response.statusMessage ?? "";

    String status = statusMessage.isEmpty
        ? statusCode.toString()
        : "$statusCode $statusMessage";
    _log("<-- $status ${options.uri} (${duration.inMilliseconds}ms)");

    if (_logHeaders) {
      response.headers.forEach(
        (name, values) => _log("$name: ${values.join(", ")}"),
      );

      if (_logBody && response.data != null) {
        _log("");
        _log(_formatBody(response.data));
      }
    }

    _log("<-- END HTTP");
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (level == LoggingInterceptorLevel.none) {
      handler.next(err);
      return;
    }

    RequestOptions options = err.requestOptions;
    Duration duration = _duration(options);

    _log("<-- HTTP FAILED: ${err.message} (${duration.inMilliseconds}ms)");

    if (_logHeaders && err.response != null) {
      err.response!.headers.forEach(
        (name, values) => _log("$name: ${values.join(", ")}"),
      );

      if (_logBody && err.response!.data != null) {
        _log("");
        _log(_formatBody(err.response!.data));
      }
    }

    handler.next(err);
  }

  bool get _logHeaders {
    return level == LoggingInterceptorLevel.headers ||
        level == LoggingInterceptorLevel.body;
  }

  bool get _logBody {
    return level == LoggingInterceptorLevel.body;
  }

  Duration _duration(RequestOptions options) {
    Object? startTime = options.extra[_startTimeKey];
    if (startTime is DateTime) {
      return DateTime.now().difference(startTime);
    }
    return Duration.zero;
  }

  String _formatBody(Object? body) {
    if (body is FormData) {
      List<String> fields = body.fields
          .map((field) => "${field.key}=${field.value}")
          .toList();
      List<String> files = body.files
          .map((file) => "${file.key}=${file.value.filename ?? "file"}")
          .toList();
      return [...fields, ...files].join("&");
    }
    if (body is List<int>) {
      return "binary ${body.length} bytes";
    }
    if (body is Stream) {
      return "stream body";
    }
    return body.toString();
  }

  void _log(Object? message) {
    printer(message);
  }
}
