import 'package:dio/dio.dart';

class ApiErrorHandler {
  static const List<int> _retryableStatusCodes = [500, 502, 503, 504];
  static const List<int> _showSnackbarStatusCodes = [400, 401, 403, 404, 409, 422];

  /// Determines if an error should be retried automatically
  static bool shouldRetry(DioException error) {
    // Retry on network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    
    // Retry on server errors (5xx)
    if (error.response != null) {
      return _retryableStatusCodes.contains(error.response!.statusCode);
    }
    
    return false;
  }

  /// Determines if an error should show a snackbar
  static bool shouldShowSnackbar(DioException error) {
    // Don't show snackbar for retryable errors (they will be retried)
    if (shouldRetry(error)) {
      return false;
    }
    
    // Show snackbar for client errors (4xx) except 401 (handled by auth interceptor)
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      return _showSnackbarStatusCodes.contains(statusCode);
    }
    
    // Show snackbar for other network errors
    return true;
  }

  /// Extracts user-friendly error message from DioException
  static String extractErrorMessage(DioException error) {
    // Handle response errors
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final responseData = error.response!.data;
      
      // Try to extract message from response data
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('message')) {
          return responseData['message'];
        }
        if (responseData.containsKey('error')) {
          return responseData['error'];
        }
      }
      
      // Fallback to status code based messages
      switch (statusCode) {
        case 400:
          return 'Bad request. Please check your input.';
        case 401:
          return 'Authentication failed. Please login again.';
        case 403:
          return 'Access denied. You don\'t have permission.';
        case 404:
          return 'Resource not found.';
        case 409:
          return 'Conflict. The resource already exists.';
        case 422:
          return 'Validation error. Please check your input.';
        case 500:
          return 'Server error. Please try again later.';
        case 502:
          return 'Bad gateway. Please try again later.';
        case 503:
          return 'Service unavailable. Please try again later.';
        case 504:
          return 'Gateway timeout. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    
    // Handle network errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.receiveTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      default:
        return 'Network error. Please try again.';
    }
  }

  /// Checks if error is a server error (5xx)
  static bool isServerError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      return statusCode != null && statusCode >= 500 && statusCode < 600;
    }
    return false;
  }

  /// Checks if error is a client error (4xx)
  static bool isClientError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      return statusCode != null && statusCode >= 400 && statusCode < 500;
    }
    return false;
  }
} 