import 'package:dio/dio.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/remote/user_model.dart';
import '../core/utils/device_timezone.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
/// auth_repository.dart
/// Talks to /auth/* endpoints and persists tokens on success.
/// Maps backend's { success, message, data } envelope into typed results
/// or throws ApiException on failure — providers don't touch Dio directly.
class AuthRepository {
  AuthRepository({Dio? dio, SecureStorageService? storage})
      : _dio = dio ?? DioClient.instance.dio,
        _storage = storage ?? SecureStorageService.instance;

  final Dio _dio;
  final SecureStorageService _storage;

  /// POST /auth/register
  /// Body: { name, username, email, password }
  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final timezone = await DeviceTimezone.getTimezone();
      debugPrint('DETECTED TIMEZONE: $timezone');
      final response = await _dio.post(ApiEndpoints.register, data: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'timezone': timezone,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }

      throw ApiException(
        response.data['message'] as String? ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /auth/login
  /// Body: { email, password, timezone }
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final timezone = await DeviceTimezone.getTimezone();
      debugPrint('DETECTED TIMEZONE: $timezone');
      final response = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
        'timezone': timezone,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }

      throw ApiException(
        response.data['message'] as String? ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// GET /auth/me — used on app start to validate an existing session
  /// and rehydrate the user (e.g. to check onboardingCompleted).
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(
          response.data['data']['user'] as Map<String, dynamic>,
        );
      }

      throw ApiException(
        response.data['message'] as String? ?? 'Session expired',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /auth/logout
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException {
      // Even if the server call fails, clear local tokens below.
    } finally {
      await _storage.clearTokens();
    }
  }

  ApiException _mapDioError(DioException e) {
    final responseMessage = e.response?.data is Map
        ? (e.response?.data['message'] as String?)
        : null;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException('Can\'t reach the server. Check your connection.');
    }

    return ApiException(
      responseMessage ?? 'Something went wrong. Please try again.',
      statusCode: e.response?.statusCode,
    );
  }
}