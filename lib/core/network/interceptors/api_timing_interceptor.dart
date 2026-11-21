import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/core/service/crash_reporting.dart';

class ApiTimingInterceptor extends Interceptor {
  static const String _startedAtKey = 'api_timing_started_at';
  static const String _metricKey = 'api_timing_http_metric';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now().microsecondsSinceEpoch;
    _startMetric(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logTiming(response.requestOptions, statusCode: response.statusCode);
    _stopMetric(response.requestOptions, response: response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _stopMetric(err.requestOptions, response: err.response);
    _logTiming(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      error: err.error?.toString() ?? err.message,
    );
    handler.next(err);
  }

  /// Firebase Performance can't see Dart networking on its own, so every Dio
  /// request gets a manual network trace. The query string is dropped: it can
  /// carry keys or user input, and Firebase groups traces by path anyway.
  void _startMetric(RequestOptions options) {
    if (!CrashReporting.enabled) return;
    final method = _httpMethod(options.method);
    if (method == null) return;
    try {
      final uri = options.uri;
      final url = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path,
      ).toString();
      final metric = FirebasePerformance.instance.newHttpMetric(url, method);
      options.extra[_metricKey] = metric;
      metric.start();
    } catch (_) {
      // Monitoring must never affect a request.
    }
  }

  void _stopMetric(RequestOptions options, {Response? response}) {
    final metric = options.extra.remove(_metricKey);
    if (metric is! HttpMetric) return;
    try {
      metric.httpResponseCode = response?.statusCode;
      metric.responseContentType = response?.headers.value(
        Headers.contentTypeHeader,
      );
      final length = response?.headers.value(Headers.contentLengthHeader);
      metric.responsePayloadSize = length == null ? null : int.tryParse(length);
      metric.stop();
    } catch (_) {}
  }

  static HttpMethod? _httpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.Get;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'PATCH':
        return HttpMethod.Patch;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'HEAD':
        return HttpMethod.Head;
      case 'OPTIONS':
        return HttpMethod.Options;
      default:
        return null;
    }
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
