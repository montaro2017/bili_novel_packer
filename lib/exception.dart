import 'package:bili_novel_packer/widget/exception_widget.dart';
import 'package:flutter/material.dart';

class NotRetryableException implements Exception, ExceptionWidgetMixin {
  final dynamic message;

  NotRetryableException(this.message);

  @override
  Widget buildExceptionWidget(BuildContext context, ExceptionWidget widget) {
    return ExceptionWidgetMixin.defaultWidget(
      message.toString(),
      widget.retry,
      retryable: false,
    );
  }
}
