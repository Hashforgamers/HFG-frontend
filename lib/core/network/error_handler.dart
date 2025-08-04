import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

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

class ErrorHandler {
  static final segmentService = locator<SegmentSdkService>();

  static void handleError(DioException error) {
    String errorMessage = 'An error occurred';
    String endpoint = '';

    endpoint = error.requestOptions.uri.toString();
  
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Connection timeout';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = 'Send timeout';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Receive timeout';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          errorMessage = 'Unauthorized access';
        } else if (statusCode == 403) {
          errorMessage = 'Forbidden access';
        } else if (statusCode == 404) {
          errorMessage = 'Resource not found';
        } else if (statusCode == 500) {
          errorMessage = 'Internal server error';
        } else {
          errorMessage = 'Server error: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'No internet connection';
        break;
      case DioExceptionType.unknown:
        errorMessage = 'Unknown error occurred';
        break;
      default:
        errorMessage = 'An error occurred';
    }

    // Track API error event
    segmentService.onApiError(
      endpoint: endpoint,
      errorMessage: errorMessage,
    );

    Get.snackbar(
      'Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  static void handleGenericError(dynamic error) {
    String errorMessage = 'An unexpected error occurred';
    
    if (error is String) {
      errorMessage = error;
    } else if (error is Exception) {
      errorMessage = error.toString();
    }

    // Track API error event for generic errors
    segmentService.onApiError(
      endpoint: 'unknown',
      errorMessage: errorMessage,
    );

    Get.snackbar(
      'Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
} 