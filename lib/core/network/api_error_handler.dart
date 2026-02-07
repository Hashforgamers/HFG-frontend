import 'package:dio/dio.dart';

class ApiErrorHandler {
  static bool shouldRetry(DioException error) {
    // Retry on network errors and server errors (5xx)
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        // Retry on server errors (5xx)
        return statusCode != null && statusCode >= 500 && statusCode < 600;
      default:
        return false;
    }
  }

  static String extractErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please try again.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return 'Unauthorized access. Please login again.';
        } else if (statusCode == 403) {
          return 'Forbidden access.';
        } else if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 500) {
          return 'Internal server error. Please try again later.';
        } else if (statusCode != null && statusCode >= 500) {
          return 'Server error. Please try again later.';
        } else {
          return 'Request failed. Please try again.';
        }
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.unknown:
        return 'An unknown error occurred. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
