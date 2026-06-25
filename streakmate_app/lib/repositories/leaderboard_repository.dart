import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/remote/friends_model.dart';

class LeaderboardRepository {
  LeaderboardRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  Future<List<LeaderboardEntry>> getFriendsLeaderboard() async {
    final r = await _dio.get('/leaderboard/friends');
    _check(r);
    return (r.data['data']['leaderboard'] as List)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _check(Response r) {
    if (r.statusCode != 200) {
      throw ApiException(r.data['message'] as String? ?? 'Failed',
          statusCode: r.statusCode);
    }
  }
}