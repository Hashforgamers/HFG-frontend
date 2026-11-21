import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/routes/app_routes.dart';

class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor(Dio _);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await locator<AuthDataRepository>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
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

    // Temporarily disable automatic logout/navigation on 401 while debugging token flow.
    // await locator<AuthDataRepository>().clearTokens();
    // if (Get.currentRoute != AppRoutes.LOGIN) {
    //   Get.offAllNamed(AppRoutes.LOGIN);
    // }

    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: 'Session expired',
        type: DioExceptionType.unknown,
      ),
    );
  }
}
