import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/remote/habit_model.dart';

class HabitRepository {
  HabitRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  /// POST /habits
  /// body: { name, category, icon, color, description?,
  ///         frequency, activeDays, startDate,
  ///         completionRule, completionThreshold,
  ///         reminderEnabled, reminderTimes }
  Future<HabitModel> createHabit({
    required String name,
    required String category,
    required String icon,
    required String color,
    String? description,
    String frequency = 'daily',
    List<int> activeDays = const [0, 1, 2, 3, 4, 5, 6],
    String? startDate,
  }) async {
    try {
      final today = startDate ?? _today();
      final r = await _dio.post(
        '/habits',
        data: {
          'name': name,
          'category': category,
          'icon': icon,
          'color': color,
          if (description != null && description.isNotEmpty)
            'description': description,
          'frequency': frequency,
          'activeDays': activeDays,
          'startDate': today,
          'completionRule': 'all_required',
          'completionThreshold': 100,
          'reminderEnabled': false,
          'reminderTimes': [],
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      _check(r, 201);
      return HabitModel.fromJson(
          r.data['data']['habit'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// GET /habits  — all active habits (used to refresh home after add)
  Future<List<HabitModel>> getAllHabits() async {
    try {
      final r = await _dio.get('/habits');
      _check(r, 200);
      return (r.data['data']['habits'] as List)
          .map((h) => HabitModel.fromJson(h as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _check(Response r, int expected) {
    if (r.statusCode != expected) {
      throw ApiException(
        r.data['message'] as String? ?? 'Request failed',
        statusCode: r.statusCode,
      );
    }
  }

  ApiException _map(DioException e) {
    final msg = e.response?.data is Map
        ? e.response?.data['message'] as String?
        : null;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException('No connection. Check your network.');
    }
    return ApiException(msg ?? 'Something went wrong.',
        statusCode: e.response?.statusCode);
  }
}
