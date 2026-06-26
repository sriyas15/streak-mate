import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/remote/user_model.dart';

class UserRepository {
  UserRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  /// GET /users/profile
  Future<UserModel> getProfile() async {
    final r = await _dio.get('/users/profile');
    _check(r);
    return UserModel.fromJson(r.data['data']['user'] as Map<String, dynamic>);
  }

  /// PATCH /users/profile  body: { name?, bio?, username? }
  Future<UserModel> updateProfile({
    String? name,
    String? bio,
    String? username,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (username != null) body['username'] = username;

    final r = await _dio.patch(
      '/users/profile',
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    _check(r);
    return UserModel.fromJson(r.data['data']['user'] as Map<String, dynamic>);
  }

  /// GET /users/settings
  Future<Map<String, dynamic>> getSettings() async {
    final r = await _dio.get('/users/settings');
    _check(r);
    return r.data['data']['settings'] as Map<String, dynamic>;
  }

  /// PATCH /users/settings
  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> updates) async {
    final r = await _dio.patch(
      '/users/settings',
      data: updates,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    _check(r);
    return r.data['data']['settings'] as Map<String, dynamic>;
  }

  /// DELETE /users/account
  Future<void> deleteAccount() async {
    final r = await _dio.delete('/users/account');
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