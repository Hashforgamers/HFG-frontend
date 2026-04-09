import 'package:dio/dio.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/interceptors/api_timing_interceptor.dart';
import 'package:hash/core/network/interceptors/auth_interceptor.dart';
import 'package:hash/core/network/interceptors/retry_interceptor.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

const bool _enableVerboseNetworkLog = false;

bool _shouldSkipVerboseNetworkLog(RequestOptions options) {
  if (!_enableVerboseNetworkLog) return true;
  final url = options.uri.toString().toLowerCase();
  // Avoid dumping full gaming cafe payload in console.
  return url.contains('/api/vendor/getallgamingcafe');
}

class NetworkConfig {
  final String baseUrl;
  final Map<String, String> baseHeaders;

  NetworkConfig({required this.baseUrl, required this.baseHeaders});

  Dio get dio {
    var options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: baseHeaders,
    );

    final dio = Dio(options);

    if (_enableVerboseNetworkLog) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: true,
          error: true,
          compact: true,
          maxWidth: 90,
          filter: (options, args) => !_shouldSkipVerboseNetworkLog(options),
        ),
      );
    }

    dio.interceptors.add(ApiTimingInterceptor());
    dio.interceptors.add(RetryInterceptor(dio: dio));
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

  NetworkProvider() {
    var options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
    );

    _dio = Dio(options);

    if (_enableVerboseNetworkLog) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: true,
          error: true,
          compact: true,
          maxWidth: 90,
          filter: (options, args) => !_shouldSkipVerboseNetworkLog(options),
        ),
      );
    }

    _dio.interceptors.add(ApiTimingInterceptor());
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
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

  Dio noAuthQuiet({Map<String, dynamic>? headers}) {
    final options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      headers: headers ?? {'Content-Type': 'application/json'},
    );

    final dio = Dio(options);
    dio.interceptors.add(ApiTimingInterceptor());
    dio.interceptors.add(RetryInterceptor(dio: dio));
    return dio;
  }
}
