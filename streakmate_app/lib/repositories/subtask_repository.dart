import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_client.dart';
import '../models/remote/subtask_model.dart';

/// subtask_repository.dart
class SubtaskRepository {
  SubtaskRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  /// GET /habits/:habitId/subtasks
  Future<List<SubtaskModel>> getSubtasks(String habitId) async {
    try {
      final response = await _dio.get(ApiEndpoints.habitSubtasks(habitId));
      if (response.statusCode == 200 && response.data['success'] == true) {
        final list = response.data['data']['subtasks'] as List;
        return list
            .map((s) => SubtaskModel.fromJson(s as Map<String, dynamic>))
            .toList();
      }
      throw ApiException(
        response.data['message'] as String? ?? 'Could not load subtasks',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : null;
      throw ApiException(msg ?? 'Something went wrong.',
          statusCode: e.response?.statusCode);
    }
  }
}

final subtaskRepositoryProvider =
    Provider<SubtaskRepository>((ref) => SubtaskRepository());

/// Family provider: subtasksProvider(habitId) → AsyncValue<List<SubtaskModel>>
/// Cached per habitId so we don't re-fetch on every rebuild.
final subtasksProvider = FutureProvider.family<List<SubtaskModel>, String>(
  (ref, habitId) async {
    return ref.watch(subtaskRepositoryProvider).getSubtasks(habitId);
  },
);
