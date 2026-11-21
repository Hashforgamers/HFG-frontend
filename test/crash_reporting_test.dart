import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/crash_reporting.dart';

void main() {
  test('network failures are non-fatal, real bugs stay fatal', () {
    final ro = RequestOptions(path: '/');
    expect(CrashReporting.isExpectedFailure(
        DioException.connectionError(requestOptions: ro, reason: 'x')), isTrue);
    expect(CrashReporting.isExpectedFailure(
        DioException.badResponse(statusCode: 500, requestOptions: ro, response: Response(requestOptions: ro, statusCode: 500))), isFalse);
    expect(CrashReporting.isExpectedFailure(Exception(
        'Failed to initialize authenticated network: [firebase_auth/network-request-failed]')), isTrue);
    expect(CrashReporting.isExpectedFailure(StateError('bug')), isFalse);
  });
}
