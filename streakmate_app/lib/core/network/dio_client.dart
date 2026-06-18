import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

/// dio_client.dart
/// Single Dio instance for the whole app, base URL resolved from env.
///
/// Base URL resolution order:
///   1. --dart-define=API_BASE_URL=...   (recommended for CI/builds)
///   2. flutter_dotenv .env (if you wire it — see api_endpoints.dart header)
///   3. AppConstants.apiBaseUrlFallback  (local dev fallback)
class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
        // Backend wraps everything in { success, message, data } — let
        // non-2xx through to our error handling rather than throwing here.
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  static final DioClient instance = DioClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;

  static String _resolveBaseUrl() {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;

    // TODO(you): if using flutter_dotenv, replace the line below with:
    //   return dotenv.env['API_BASE_URL'] ?? AppConstants.apiBaseUrlFallback;
    return AppConstants.apiBaseUrlFallback;
  }
}