import 'package:dio/dio.dart';

class RetryInterceptor extends QueuedInterceptorsWrapper {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryStatusCodes;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.retryStatusCodes = const [500, 502, 503, 504],
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final retryCount = _getRetryCount(requestOptions);

    if (_shouldRetry(err) && retryCount < maxRetries) {
      requestOptions.extra['retryCount'] = retryCount + 1;

      final delay = retryDelay * (retryCount + 1);
      await Future.delayed(delay);

      try {
        final response = await dio.request(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          options: Options(
            method: requestOptions.method,
            headers: requestOptions.headers,
            responseType: requestOptions.responseType,
            contentType: requestOptions.contentType,
            validateStatus: requestOptions.validateStatus,
            receiveDataWhenStatusError:
                requestOptions.receiveDataWhenStatusError,
            extra: requestOptions.extra,
            followRedirects: requestOptions.followRedirects,
            maxRedirects: requestOptions.maxRedirects,
            requestEncoder: requestOptions.requestEncoder,
            responseDecoder: requestOptions.responseDecoder,
            listFormat: requestOptions.listFormat,
          ),
        );

        return handler.resolve(response);
      } catch (_) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    if (_isDecimalBackendError(err)) {
      return false;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    final statusCode = err.response?.statusCode;
    if (statusCode != null && retryStatusCodes.contains(statusCode)) {
      return true;
    }

    return false;
  }

  bool _isDecimalBackendError(DioException err) {
    final data = err.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = (data['error'] ?? data['message'] ?? '').toString();
      return msg.contains("name 'Decimal' is not defined");
    }
    if (data is String) {
      return data.contains("name 'Decimal' is not defined");
    }
    return false;
  }

  int _getRetryCount(RequestOptions options) {
    return options.extra['retryCount'] as int? ?? 0;
  }
}
