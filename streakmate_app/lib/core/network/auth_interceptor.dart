import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

/// auth_interceptor.dart
/// - Attaches `Authorization: Bearer <token>` to every request (except
///   register/login/refresh, which don't need it).
/// - On a 401 response, attempts a single silent refresh via
///   POST /auth/refresh-token, then retries the original request once.
/// - If refresh also fails, clears tokens and propagates the 401 so the
///   app can route back to the Login screen.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._dio);

  final Dio _dio;
  final _storage = SecureStorageService.instance;

  static const _publicPaths = <String>[
    ApiEndpoints.register,
    ApiEndpoints.login,
    ApiEndpoints.refreshToken,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
  ];

  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final isPublic = _publicPaths.any((p) => options.path.startsWith(p));
    if (!isPublic) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Backend uses validateStatus < 500, so a 401 arrives here as a normal
    // response rather than a DioException. Intercept it the same way.
    if (response.statusCode == 401 &&
        !_publicPaths.any((p) => response.requestOptions.path.startsWith(p))) {
      final retried = await _handleUnauthorized(response.requestOptions);
      if (retried != null) {
        handler.resolve(retried);
        return;
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !_publicPaths.any((p) => err.requestOptions.path.startsWith(p))) {
      final retried = await _handleUnauthorized(err.requestOptions);
      if (retried != null) {
        handler.resolve(retried);
        return;
      }
    }
    handler.next(err);
  }

  Future<Response?> _handleUnauthorized(RequestOptions failedRequest) async {
    if (_isRefreshing) return null; // avoid refresh storms
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        await _storage.clearTokens();
        return null;
      }

      final refreshResponse = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (refreshResponse.statusCode == 200 &&
          refreshResponse.data['success'] == true) {
        final data = refreshResponse.data['data'];
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;

        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // Retry the original request with the new token
        failedRequest.headers['Authorization'] = 'Bearer $newAccessToken';
        return _dio.fetch(failedRequest);
      } else {
        await _storage.clearTokens();
        return null;
      }
    } catch (_) {
      await _storage.clearTokens();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}