import 'package:bili_novel_packer/novel_source/base/cloudflare_interceptor.dart';
import 'package:flutter/material.dart';

class ErrorRetryWidget extends StatelessWidget {
  final dynamic error;
  final void Function()? retry;

  const ErrorRetryWidget({
    super.key,
    required this.error,
    this.retry,
  });

  @override
  Widget build(BuildContext context) {
    if (error is CloudflareException) {
      return _cloudflare();
    }
    return _fallback();
  }

  Widget _fallback() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text(error.toString()),
      ),
    );
  }

  Widget _cloudflare() {
    if (error is CloudflareException) {
      if (error.cloudflareType == CloudflareExceptionType.challenge) {
        return _cloudflareChallenge();
      }
    }
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text("Cloudflare异常"),
      ),
    );
  }

  Widget _cloudflareChallenge() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("请先完成Cloudflare验证，验证后点击重试按钮"),
        _retryButton(),
      ],
    );
  }

  Widget _retryButton() {
    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: FilledButton(
        onPressed: () {
          retry?.call();
        },
        child: Text("重试"),
      ),
    );
  }
}
