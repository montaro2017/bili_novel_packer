import 'package:flutter/material.dart';

class ExceptionWidget extends StatelessWidget {
  final dynamic e;
  final void Function()? retry;

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
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Text(e.toString()),
      ),
    );
  }
}

mixin ExceptionWidgetMixin on Exception {
  Widget buildExceptionWidget(BuildContext context, ExceptionWidget widget);

  static Widget defaultWidget(
    String message,
    ExceptionWidget widget, {
    bool retry = true,
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
            if (retry && widget.retry != null)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: FilledButton(
                  onPressed: () {
                    widget.retry!.call();
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
