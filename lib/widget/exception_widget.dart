import 'package:bili_novel_packer/exception.dart';
import 'package:flutter/material.dart';

typedef RetryFunction = Function();

class ExceptionWidget extends StatelessWidget {
  final dynamic e;
  final RetryFunction? retry;

  const ExceptionWidget({
    super.key,
    required this.e,
    this.retry,
  });

  @override
  Widget build(BuildContext context) {
    if (e is ExceptionWidgetMixin) {
      return e.buildExceptionWidget(context, this);
    }
    return _fallback();
  }

  Widget _fallback() {
    if (e is NotRetryableException) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(e.toString()),
        ),
      );
    }
    return ExceptionWidgetMixin.defaultWidget(e.toString(), retry);
  }
}

mixin ExceptionWidgetMixin on Exception {
  Widget buildExceptionWidget(BuildContext context, ExceptionWidget widget);

  static Widget defaultWidget(
    String message,
    RetryFunction? retry, {
    bool retryable = true,
  }) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (retryable && retry != null)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: FilledButton(
                  onPressed: () {
                    retry.call();
                  },
                  child: Text("重试"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
