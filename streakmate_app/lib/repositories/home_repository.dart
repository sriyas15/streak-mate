import 'package:dio/dio.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/remote/habit_log_model.dart';

/// home_repository.dart
/// Wraps GET /habits/today, POST /habits/:id/logs,
/// PATCH .../subtasks/:subtaskId, POST .../complete
class HomeRepository {
  HomeRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  /// GET /habits/today
  /// Returns each habit with todayLog embedded (null if no log yet today).
  Future<List<TodayHabitModel>> getTodayHabits() async {
    try {
      final response = await _dio.get(ApiEndpoints.habitsToday);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data']['habits'] as List;
        return list
            .map((h) => TodayHabitModel.fromJson(h as Map<String, dynamic>))
            .toList();
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not load today\'s habits',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// POST /habits/:habitId/logs
  /// Creates (or upserts) today's log for a habit so subtask results exist.
  Future<HabitLogModel> createLog(String habitId) async {
    try {
      final today = _today();
      final response = await _dio.post(
        ApiEndpoints.habitLogs(habitId),
        data: {'date': today},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 201 && response.data['success'] == true) {
        return HabitLogModel.fromJson(
            response.data['data']['log'] as Map<String, dynamic>);
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not create log',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// PATCH /habits/:habitId/logs/:date/subtasks/:subtaskId
  /// body: { isCompleted: true/false, value: null }
  Future<HabitLogModel> updateSubtaskResult({
    required String habitId,
    required String subtaskId,
    required bool isCompleted,
    num? value,
  }) async {
    try {
      final today = _today();
      final response = await _dio.patch(
        ApiEndpoints.habitLogSubtask(habitId, today, subtaskId),
        data: {'isCompleted': isCompleted, 'value': value},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return HabitLogModel.fromJson(
            response.data['data']['log'] as Map<String, dynamic>);
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not update subtask',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// POST /habits/:habitId/logs/:date/complete
  Future<HabitLogModel> markComplete(String habitId) async {
    try {
      final today = _today();
      final response = await _dio.post(
        ApiEndpoints.habitLogComplete(habitId, today),
        data: {},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return HabitLogModel.fromJson(
            response.data['data']['log'] as Map<String, dynamic>);
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not mark complete',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// POST /habits/:habitId/logs/:date/uncomplete
  Future<HabitLogModel> markUncomplete(String habitId) async {
    try {
      final today = _today();
      final response = await _dio.post(
        ApiEndpoints.habitLogUncomplete(habitId, today),
        data: {},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return HabitLogModel.fromJson(
            response.data['data']['log'] as Map<String, dynamic>);
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not mark incomplete',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  ApiException _map(DioException e) {
    final msg = e.response?.data is Map
        ? (e.response?.data['message'] as String?)
        : null;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException('No connection. Check your network.');
    }
    return ApiException(msg ?? 'Something went wrong.',
        statusCode: e.response?.statusCode);
  }
}