import 'package:dio/dio.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/remote/habit_model.dart';

/// onboarding_repository.dart
/// Talks to /onboarding/* endpoints. Every method assumes a valid bearer
/// token is already attached by AuthInterceptor (onboarding routes all
/// require `authenticate` preHandler server-side).
class OnboardingRepository {
  OnboardingRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  /// GET /onboarding/status
  /// Returns { onboardingCompleted, onboardingStep, selectedGoal }
  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _dio.get(ApiEndpoints.onboardingStatus);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['status'] as Map<String, dynamic>;
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not fetch onboarding status',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /onboarding/goal  body: { selectedGoal }
  Future<void> setGoal(String selectedGoal) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.onboardingGoal,
        data: {'selectedGoal': selectedGoal},
      );
      if (response.statusCode == 200 && response.data['success'] == true) return;
      throw ApiException(
        response.data['message'] as String? ?? 'Could not save your goal',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /onboarding/habits  body: { categories: [] }
  /// Returns the REAL created Habit docs (with subtasks embedded), so the
  /// next screen (sub-task setup) renders actual persisted subtask IDs —
  /// not the static template mirrors.
  Future<List<HabitModel>> selectHabits(List<String> categories) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.onboardingHabits,
        data: {'categories': categories},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final habitsJson = response.data['data']['habits'] as List;
        return habitsJson
            .map((h) => HabitModel.fromJson(h as Map<String, dynamic>))
            .toList();
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not create your habits',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /onboarding/subtasks
  /// body: { habitSubtasks: [{ habitId, enabledSubtaskIds, customSubtasks? }] }
  Future<void> configureSubtasks(List<Map<String, dynamic>> habitSubtasks) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.onboardingSubtasks,
        data: {'habitSubtasks': habitSubtasks},
      );
      if (response.statusCode == 200 && response.data['success'] == true) return;
      throw ApiException(
        response.data['message'] as String? ?? 'Could not save sub-tasks',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /onboarding/reminders
  /// body: { reminders: [{ habitId, times: ['08:00'], days: [0..6] }] }
  /// Passing an empty list is valid — backend just advances the step.
  Future<void> setReminders(List<Map<String, dynamic>> reminders) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.onboardingReminders,
        data: {'reminders': reminders},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) return;
      throw ApiException(
        response.data['message'] as String? ?? 'Could not save reminders',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /onboarding/complete
  /// Returns { user, habits } — habits include populated subtasks.
  Future<List<HabitModel>> complete() async {
    try {
      final response = await _dio.post(
        ApiEndpoints.onboardingComplete,
        data: {},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final habitsJson = response.data['data']['habits'] as List;
        return habitsJson
            .map((h) => HabitModel.fromJson(h as Map<String, dynamic>))
            .toList();
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not complete onboarding',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
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