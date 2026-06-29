import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/remote/calendar_model.dart';

class CalendarRepository {
  CalendarRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  /// GET /calendar/month?month=2024-06
  Future<CalendarMonth> getMonth(String month) async {
    try {
      final r = await _dio.get(
        '/calendar/month',
        queryParameters: {'month': month},
      );
      _check(r);
      return CalendarMonth.fromJson(
          r.data['data']['calendar'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// GET /calendar/day/:date  e.g. 2024-06-04
  Future<CalendarDayDetail> getDay(String date) async {
    try {
      final r = await _dio.get('/calendar/day/$date');
      _check(r);
      return CalendarDayDetail.fromJson(
          r.data['data']['day'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  void _check(Response r) {
    if (r.statusCode != 200) {
      throw ApiException(
        r.data['message'] as String? ?? 'Calendar request failed',
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