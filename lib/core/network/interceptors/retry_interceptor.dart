import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hash/core/network/error_handler.dart';

class RetryInterceptor extends QueuedInterceptorsWrapper {
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryStatusCodes;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.retryStatusCodes = const [500, 502, 503, 504],
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check if this is a retryable error
    if (_shouldRetry(err)) {
      final requestOptions = err.requestOptions;
      final retryCount = _getRetryCount(requestOptions);

      if (retryCount < maxRetries) {
        // Increment retry count
        requestOptions.extra['retryCount'] = retryCount + 1;

        // Wait before retrying
        await Future.delayed(retryDelay * (retryCount + 1));

        try {
          // Retry the request
          final response = await _retryRequest(requestOptions);
          return handler.resolve(response);
        } catch (retryError) {
          // If retry also fails, continue with the original error
          return handler.next(err);
        }
      } else {}
    }

    // Continue with normal error handling for non-retryable errors
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return ApiErrorHandler.shouldRetry(err);
  }

  int _getRetryCount(RequestOptions options) {
    return options.extra['retryCount'] as int? ?? 0;
  }

  Future<Response> _retryRequest(RequestOptions options) async {
    final dio = Dio();

    // Copy the original request options
    final retryOptions = Options(
      method: options.method,
      headers: options.headers,
      responseType: options.responseType,
      contentType: options.contentType,
      validateStatus: options.validateStatus,
      receiveDataWhenStatusError: options.receiveDataWhenStatusError,
      extra: options.extra,
      followRedirects: options.followRedirects,
      maxRedirects: options.maxRedirects,
      requestEncoder: options.requestEncoder,
      responseDecoder: options.responseDecoder,
      listFormat: options.listFormat,
    );

    return await dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: retryOptions,
    );
  }
}
