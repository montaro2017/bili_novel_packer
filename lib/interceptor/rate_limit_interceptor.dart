import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';

enum RateLimitStrategy {
  fixedInterval,
  tokenBucket,
  slidingWindow,
}

class RateLimitInterceptor extends QueuedInterceptor {
  final _RateLimitPolicy _policy;

  RateLimitInterceptor(int times, Duration per)
    : this.fixedInterval(times, per);

  RateLimitInterceptor.fixedInterval(int times, Duration per)
    : _policy = _buildFixedIntervalPolicy(times, per);

  RateLimitInterceptor.tokenBucket(
    int times,
    Duration per, {
    int? capacity,
  }) : _policy = _buildTokenBucketPolicy(times, per, capacity: capacity);

  RateLimitInterceptor.slidingWindow(int times, Duration per)
    : _policy = _buildSlidingWindowPolicy(times, per);

  RateLimitInterceptor.strategy(
    int times,
    Duration per, {
    RateLimitStrategy strategy = RateLimitStrategy.fixedInterval,
    int? tokenBucketCapacity,
  }) : _policy = _buildStrategyPolicy(
         times,
         per,
         strategy: strategy,
         tokenBucketCapacity: tokenBucketCapacity,
       );

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      await _policy.wait();
      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  static _RateLimitPolicy _buildStrategyPolicy(
    int times,
    Duration per, {
    required RateLimitStrategy strategy,
    int? tokenBucketCapacity,
  }) {
    switch (strategy) {
      case RateLimitStrategy.fixedInterval:
        return _buildFixedIntervalPolicy(times, per);
      case RateLimitStrategy.tokenBucket:
        return _buildTokenBucketPolicy(
          times,
          per,
          capacity: tokenBucketCapacity,
        );
      case RateLimitStrategy.slidingWindow:
        return _buildSlidingWindowPolicy(times, per);
    }
  }

  static _RateLimitPolicy _buildFixedIntervalPolicy(int times, Duration per) {
    if (_isUnlimited(times, per)) {
      return _UnlimitedRateLimitPolicy();
    }
    return _FixedIntervalRateLimitPolicy(times, per);
  }

  static _RateLimitPolicy _buildTokenBucketPolicy(
    int times,
    Duration per, {
    int? capacity,
  }) {
    if (_isUnlimited(times, per)) {
      return _UnlimitedRateLimitPolicy();
    }
    if (capacity != null && capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be greater than 0');
    }
    return _TokenBucketRateLimitPolicy(
      times,
      per,
      capacity: capacity ?? times,
    );
  }

  static _RateLimitPolicy _buildSlidingWindowPolicy(int times, Duration per) {
    if (_isUnlimited(times, per)) {
      return _UnlimitedRateLimitPolicy();
    }
    return _SlidingWindowRateLimitPolicy(times, per);
  }

  static bool _isUnlimited(int times, Duration per) {
    return times <= 0 || per <= Duration.zero;
  }
}

abstract class _RateLimitPolicy {
  Future<void> wait();
}

class _UnlimitedRateLimitPolicy implements _RateLimitPolicy {
  @override
  Future<void> wait() async {}
}

abstract class _StopwatchRateLimitPolicy implements _RateLimitPolicy {
  final Stopwatch _stopwatch = Stopwatch()..start();

  Duration get _now => _stopwatch.elapsed;
}

class _FixedIntervalRateLimitPolicy extends _StopwatchRateLimitPolicy {
  late final Duration _gap;
  Duration? _lastRequestTime;

  _FixedIntervalRateLimitPolicy(int times, Duration per) {
    _gap = Duration(microseconds: (per.inMicroseconds / times).ceil());
  }

  @override
  Future<void> wait() async {
    if (_lastRequestTime == null) {
      _lastRequestTime = _now;
      return;
    }

    Duration waitTime = _gap - (_now - _lastRequestTime!);
    if (waitTime > Duration.zero) {
      await Future<void>.delayed(waitTime);
    }
    _lastRequestTime = _now;
  }
}

class _TokenBucketRateLimitPolicy extends _StopwatchRateLimitPolicy {
  final int _capacity;
  final double _tokensPerMicrosecond;
  late double _tokens;
  Duration _lastRefillTime = Duration.zero;

  _TokenBucketRateLimitPolicy(
    int times,
    Duration per, {
    required int capacity,
  }) : _capacity = capacity,
       _tokensPerMicrosecond = times / per.inMicroseconds {
    _tokens = capacity.toDouble();
  }

  @override
  Future<void> wait() async {
    while (true) {
      _refill();
      if (_tokens >= 1) {
        _tokens -= 1;
        return;
      }

      double missingTokens = 1 - _tokens;
      int waitMicroseconds = (missingTokens / _tokensPerMicrosecond).ceil();
      await Future<void>.delayed(Duration(microseconds: waitMicroseconds));
    }
  }

  void _refill() {
    Duration now = _now;
    int elapsedMicroseconds = (now - _lastRefillTime).inMicroseconds;
    if (elapsedMicroseconds <= 0) {
      return;
    }

    _tokens = (_tokens + elapsedMicroseconds * _tokensPerMicrosecond).clamp(
      0.0,
      _capacity.toDouble(),
    );
    _lastRefillTime = now;
  }
}

class _SlidingWindowRateLimitPolicy extends _StopwatchRateLimitPolicy {
  final int _times;
  final Duration _window;
  final Queue<Duration> _requestTimes = Queue();

  _SlidingWindowRateLimitPolicy(this._times, this._window);

  @override
  Future<void> wait() async {
    while (true) {
      Duration now = _now;
      _removeExpiredRequests(now);

      if (_requestTimes.length < _times) {
        _requestTimes.addLast(now);
        return;
      }

      Duration waitTime = _window - (now - _requestTimes.first);
      if (waitTime <= Duration.zero) {
        continue;
      }
      await Future<void>.delayed(waitTime);
    }
  }

  void _removeExpiredRequests(Duration now) {
    while (_requestTimes.isNotEmpty &&
        now - _requestTimes.first >= _window) {
      _requestTimes.removeFirst();
    }
  }
}
