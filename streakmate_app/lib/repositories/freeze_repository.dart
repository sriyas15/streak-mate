import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';

/// freeze_repository.dart
/// Talks to GET /freeze/balance, POST /freeze/activate,
/// POST /freeze/cheat-day/activate, GET /freeze/history
class FreezeBalance {
  final int freezesRemaining;
  final int freezesUsed;
  final int totalFreezesAlloted;
  final int cheatDaysRemaining;
  final int cheatDaysUsed;
  final int cheatDaysAlloted;

  const FreezeBalance({
    required this.freezesRemaining,
    required this.freezesUsed,
    required this.totalFreezesAlloted,
    required this.cheatDaysRemaining,
    required this.cheatDaysUsed,
    required this.cheatDaysAlloted,
  });

  factory FreezeBalance.fromJson(Map<String, dynamic> json) {
    return FreezeBalance(
      freezesRemaining: json['freezesRemaining'] as int? ?? 0,
      freezesUsed: json['freezesUsed'] as int? ?? 0,
      totalFreezesAlloted: json['totalFreezesAlloted'] as int? ?? 3,
      cheatDaysRemaining: json['cheatDaysRemaining'] as int? ?? 0,
      cheatDaysUsed: json['cheatDaysUsed'] as int? ?? 0,
      cheatDaysAlloted: json['cheatDaysAlloted'] as int? ?? 2,
    );
  }
}

class FreezeHistoryItem {
  final String date;
  final String type; // 'freeze' | 'cheat'
  final String? reason;

  const FreezeHistoryItem({
    required this.date,
    required this.type,
    this.reason,
  });

  factory FreezeHistoryItem.fromJson(Map<String, dynamic> json) {
    return FreezeHistoryItem(
      date: json['date'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String?,
    );
  }
}

class FreezeRepository {
  FreezeRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  /// GET /freeze/balance
  Future<FreezeBalance> getBalance() async {
    try {
      final r = await _dio.get('/freeze/balance');
      _check(r, 200);
      return FreezeBalance.fromJson(
          r.data['data']['balance'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// POST /freeze/activate  body: { date, reason? }
  Future<FreezeBalance> activateFreeze({
    required String date,
    String? reason,
  }) async {
    try {
      final r = await _dio.post('/freeze/activate', data: {
        'date': date,
        if (reason != null) 'reason': reason,
      });
      _check(r, 200);
      return FreezeBalance.fromJson(
          r.data['data']['balance'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// POST /freeze/cheat-day/activate  body: { date }
  Future<FreezeBalance> activateCheatDay({required String date}) async {
    try {
      final r = await _dio.post('/freeze/cheat-day/activate', data: {
        'date': date,
      });
      _check(r, 200);
      return FreezeBalance.fromJson(
          r.data['data']['balance'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// GET /freeze/history
  Future<List<FreezeHistoryItem>> getHistory() async {
    try {
      final r = await _dio.get('/freeze/history');
      _check(r, 200);
      return (r.data['data']['history'] as List)
          .map((h) => FreezeHistoryItem.fromJson(h as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
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