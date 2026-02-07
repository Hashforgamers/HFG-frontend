import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/network/api_error_handler.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

class ErrorHandler {
  static final segmentService = locator<SegmentSdkService>();

  static void handleError(DioException error) {
    final errorMessage = ApiErrorHandler.extractErrorMessage(error);
    final endpoint = error.requestOptions.uri.toString();

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
