import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // ── Debug logging — prints every request + response to Flutter console ──
    // Automatically disabled in release builds via kDebugMode.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint('[DIO] $obj'),
        ),
      );
    }

    _dio.interceptors.add(AuthInterceptor(_dio));
  }

  static final DioClient instance = DioClient._internal();
  late final Dio _dio;

  Dio get dio => _dio;

  static String _resolveBaseUrl() {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000/api/v1');
    if (fromDefine.isNotEmpty) return fromDefine;
    // TODO(you): if using flutter_dotenv, replace the line below with:
    //   return dotenv.env['API_BASE_URL'] ?? AppConstants.apiBaseUrlFallback;
    return AppConstants.apiBaseUrlFallback;
  }
}