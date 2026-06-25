import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/remote/achievement_model.dart';

class AchievementRepository {
  AchievementRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  Future<List<AchievementModel>> getAllAchievements() async {
    try {
      final r = await _dio.get('/achievements');
      if (r.statusCode == 200 && r.data['success'] == true) {
        return (r.data['data']['achievements'] as List)
            .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // If Achievement collection not seeded yet, return defaults
      return AchievementModel.defaults;
    } catch (_) {
      return AchievementModel.defaults;
    }
  }
}