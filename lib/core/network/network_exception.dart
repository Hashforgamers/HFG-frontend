// network_exception.dart
import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException({required this.message, this.statusCode});

  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return NetworkException(message: 'Connection timeout', statusCode: 408);
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Receive timeout', statusCode: 408);
      default:
        return NetworkException(
          message: 'Something went wrong',
          statusCode: error.response?.statusCode,
        );
    }
  }
}
