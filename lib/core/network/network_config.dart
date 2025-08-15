import 'package:dio/dio.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/interceptors/auth_interceptor.dart';
import 'package:hash/core/network/interceptors/retry_interceptor.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class NetworkConfig {
  final String baseUrl;
  final Map<String, String> baseHeaders;

  NetworkConfig({required this.baseUrl, required this.baseHeaders});

  Dio get dio {
    var options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: baseHeaders,
    );

    final dio = Dio(options);

    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );

    // Add retry interceptor for 500 errors
    dio.interceptors.add(RetryInterceptor());

    dio.interceptors.add(AuthInterceptor(dio));

    return dio;
  }

  static Future<NetworkConfig> auth({
    bool forceRefresh = false,
    String? overrideToken,
    Map<String, String>? extraHeaders,
    String? hostUrl,
  }) async {
    try {
      String? token = overrideToken;
      if (token == null) {
        token = await locator<AuthDataRepository>().getAccessToken();
        if (token == null) {
          throw DioException(
            requestOptions: RequestOptions(path: ''),
            error: 'No access token available',
          );
        }
      }

      var headers = {'Authorization': 'Bearer $token'};
      if (extraHeaders != null) headers.addAll(extraHeaders);

      return NetworkConfig(
        baseUrl: hostUrl ?? ApiEndpoints.baseUrl,
        baseHeaders: headers,
      );
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'Failed to configure authenticated network: ${e.toString()}',
      );
    }
  }

  static NetworkConfig noAuth({
    Map<String, String> headers = const {},
    Duration cacheMaxAge = Duration.zero,
    bool forceRefresh = false,
    String? hostUrl,
  }) {
    return NetworkConfig(
      baseUrl: hostUrl ?? ApiEndpoints.baseUrl,
      baseHeaders: headers,
    );
  }
}

class NetworkProvider {
  late final Dio _dio;
  final _authDataRepo = locator<AuthDataRepository>();

  NetworkProvider() {
    var options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    );

    _dio = Dio(options);

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );

    // Add retry interceptor for 500 errors
    _dio.interceptors.add(RetryInterceptor());
  }

  Future<Dio> auth() async {
    try {
      final remoteRepo = locator<RemoteRepoInterface>();
      final jwt = await remoteRepo.getJwtFromPreferences();
      if (jwt == null) {
        throw Exception('No auth token available');
      }
      final token = jwt;

      _dio.options.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      return _dio;
    } catch (e) {
      throw Exception('Failed to initialize authenticated network: $e');
    }
  }

  Dio noAuth({Map<String, dynamic>? headers}) {
    _dio.options.headers = headers ?? {'Content-Type': 'application/json'};
    return _dio;
  }
}
