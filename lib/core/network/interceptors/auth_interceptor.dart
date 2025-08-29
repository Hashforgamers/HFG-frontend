import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_RetryRequest> _pendingRequests = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // If it's a refresh token request, let it pass through
    if (options.path.contains('refresh')) {
      return handler.next(options);
    }

    // For all other requests, ensure we have a valid token
    try {
      // final token = await locator<AuthDataRepository>().getAccessToken();
      final token = '';
      options.headers['Authorization'] = 'Bearer $token';
      return handler.next(options);
        } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Failed to get access token: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final options = err.requestOptions;

    // If the token refresh request fails, we have a bigger problem
    if (options.path.contains('refresh')) {
      // Clear tokens and reject all pending requests
      await locator<AuthDataRepository>().clearTokens();
      _rejectPendingRequests('Session expired');
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Failed to refresh token',
          type: DioExceptionType.unknown,
        ),
      );
    }

    // Create a completer for this request
    final completer = Completer<Response>();
    _pendingRequests.add(_RetryRequest(options, completer));

    try {
      String? newAccessToken;

      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          // Get refresh token
          final refreshToken =
              await locator<AuthDataRepository>().getRefreshToken();
          if (refreshToken == null) {
            throw DioException(
              requestOptions: options,
              error: 'No refresh token available',
              type: DioExceptionType.unknown,
            );
          }

          // Call refresh token endpoint using RemoteRepo
          final remoteRepo = locator<RemoteRepoInterface>();
          // final loginResponse = await remoteRepo.refreshToken(refreshToken);

          // Save new tokens
          // await locator<AuthDataRepository>().saveTokens(
          //   accessToken: loginResponse.accessToken,
          //   refreshToken: loginResponse.refreshToken,
          // );

          // newAccessToken = loginResponse.accessToken;xs

          // Retry all pending requests with new token
          // await _retryPendingRequests(newAccessToken);
        } finally {
          _isRefreshing = false;
        }
      } else {
        // Wait for the refresh to complete and get the new token
        while (_isRefreshing) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        newAccessToken = await locator<AuthDataRepository>().getAccessToken();
        if (newAccessToken != null) {
          // Retry this request with the new token
          final response = await _retryRequest(options, newAccessToken);
          completer.complete(response);
        }
      }

      if (newAccessToken == null) {
        throw DioException(
          requestOptions: options,
          error: 'Failed to get new access token',
          type: DioExceptionType.unknown,
        );
      }

      final response = await completer.future;
      return handler.resolve(response);
    } catch (e) {
      // If refresh fails, clear tokens and reject all requests
      await locator<AuthDataRepository>().clearTokens();
      _rejectPendingRequests('Session expired');

      return handler.reject(
        DioException(
          requestOptions: options,
          error: e is DioException ? e.error : 'Authentication failed: $e',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions options,
    String newToken,
  ) async {
    final retryOptions = Options(
      method: options.method,
      headers: {
        ...options.headers,
        'Authorization': 'Bearer $newToken',
      },
    );

    return await _dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: retryOptions,
    );
  }

  void _rejectPendingRequests(String error) {
    for (var request in _pendingRequests) {
      request.completer.completeError(
        DioException(
          requestOptions: request.options,
          error: error,
          type: DioExceptionType.unknown,
        ),
      );
    }
    _pendingRequests.clear();
  }

  Future<void> _retryPendingRequests(String newToken) async {
    final requests = List<_RetryRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (var request in requests) {
      try {
        final response = await _retryRequest(request.options, newToken);
        request.completer.complete(response);
      } catch (e) {
        request.completer.completeError(e);
      }
    }
  }
}

class _RetryRequest {
  final RequestOptions options;
  final Completer<Response> completer;

  _RetryRequest(this.options, this.completer);
}
