import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/remote/friends_model.dart';

class FriendsRepository {
  FriendsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  Future<List<FriendModel>> getFriends() async {
    final r = await _dio.get('/friends');
    _check(r);
    return (r.data['data']['friends'] as List)
        .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FriendModel>> searchUsers(String query) async {
    final r = await _dio.get('/friends/search', queryParameters: {'q': query});
    _check(r);
    return (r.data['data']['users'] as List)
        .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FriendModel>> getSuggestions() async {
    final r = await _dio.get('/friends/suggestions');
    _check(r);
    return (r.data['data']['suggestions'] as List)
        .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FriendRequestModel>> getIncomingRequests() async {
    final r = await _dio.get('/friends/requests');
    _check(r);
    return (r.data['data']['requests'] as List)
        .map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendRequest(String userId) async {
    final r = await _dio.post('/friends/request/$userId',
        data: {}, options: Options(headers: {'Content-Type': 'application/json'}));
    _check(r);
  }

  Future<void> acceptRequest(String userId) async {
    final r = await _dio.post('/friends/accept/$userId',
        data: {}, options: Options(headers: {'Content-Type': 'application/json'}));
    _check(r);
  }

  Future<void> rejectRequest(String userId) async {
    final r = await _dio.post('/friends/reject/$userId',
        data: {}, options: Options(headers: {'Content-Type': 'application/json'}));
    _check(r);
  }

  Future<void> nudgeFriend(String userId) async {
    final r = await _dio.post('/friends/$userId/nudge',
        data: {}, options: Options(headers: {'Content-Type': 'application/json'}));
    _check(r);
  }

  Future<void> removeFriend(String userId) async {
    final r = await _dio.delete('/friends/$userId');
    _check(r);
  }

  void _check(Response r) {
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw ApiException(
        r.data['message'] as String? ?? 'Request failed',
        statusCode: r.statusCode,
      );
    }
  }
}