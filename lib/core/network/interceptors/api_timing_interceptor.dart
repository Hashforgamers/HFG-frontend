import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiTimingInterceptor extends Interceptor {
  static const String _startedAtKey = 'api_timing_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now().microsecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logTiming(response.requestOptions, statusCode: response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logTiming(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      error: err.error?.toString() ?? err.message,
    );
    handler.next(err);
  }

  void _logTiming(RequestOptions options, {int? statusCode, String? error}) {
    if (!kDebugMode) return;

    final startedAt = options.extra[_startedAtKey] as int?;
    if (startedAt == null) return;

    final elapsedMs =
        (DateTime.now().microsecondsSinceEpoch - startedAt) / 1000;
    final uri = options.uri.toString();
    final retryCount = options.extra['retryCount'] as int? ?? 0;
    final retrySuffix = retryCount > 0 ? ' retry=$retryCount' : '';
    final statusSuffix = statusCode != null ? ' status=$statusCode' : '';
    final errorSuffix = error != null && error.isNotEmpty
        ? ' error=$error'
        : '';

    debugPrint(
      '[API TIME] ${options.method.toUpperCase()} $uri | '
      '${elapsedMs.toStringAsFixed(0)} ms$statusSuffix$retrySuffix$errorSuffix',
    );
  }
}
