import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_exception.dart';
import '../models/remote/analytics_model.dart';

class AnalyticsRepository {
  AnalyticsRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;
  final Dio _dio;

  /// GET /analytics/overview?period=week|month
  Future<AnalyticsOverview> getOverview(String period) async {
    try {
      final r = await _dio.get('/analytics/overview',
          queryParameters: {'period': period});
      _check(r);
      return AnalyticsOverview.fromJson(
          r.data['data']['overview'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// GET /analytics/weekly-summary
  Future<WeeklySummary> getWeeklySummary() async {
    try {
      final r = await _dio.get('/analytics/weekly-summary');
      _check(r);
      return WeeklySummary.fromJson(
          r.data['data']['summary'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// GET /analytics/categories?period=week|month
  Future<List<CategoryPerformance>> getCategoryPerformance(
      String period) async {
    try {
      final r = await _dio.get('/analytics/categories',
          queryParameters: {'period': period});
      _check(r);
      return (r.data['data']['categories'] as List)
          .map((c) =>
              CategoryPerformance.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// GET /analytics/insights
  Future<List<AnalyticsInsight>> getInsights() async {
    try {
      final r = await _dio.get('/analytics/insights');
      _check(r);
      return (r.data['data']['insights'] as List)
          .map((i) =>
              AnalyticsInsight.fromJson(i as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// GET /analytics/heatmap?year=2024
  Future<List<HeatmapDay>> getHeatmap(int year) async {
    try {
      final r = await _dio.get('/analytics/heatmap',
          queryParameters: {'year': year});
      _check(r);
      final raw = r.data['data']['heatmap'];

      // Handle both shapes:
      // Shape A (map): { "2024-01-01": { isProductive: true, value: 2 } }
      // Shape B (list): [ { date: "2024-01-01", isProductive: true } ]
      // Shape C (list of strings): [ "2024-01-01", ... ] — productive dates
      if (raw is Map) {
        return (raw as Map<String, dynamic>).entries.map((e) {
          final val = e.value;
          if (val is Map<String, dynamic>) {
            return HeatmapDay.fromJson(e.key, val);
          }
          // value is just a number (e.g. completion score)
          return HeatmapDay(
            date: e.key,
            value: (val as num?)?.toInt() ?? 0,
            isProductive: (val as num?)?.toInt() == 2,
          );
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      } else if (raw is List) {
        return raw.map((item) {
          if (item is String) {
            // list of productive date strings
            return HeatmapDay(date: item, value: 2, isProductive: true);
          }
          final m = item as Map<String, dynamic>;
          final date = m['date'] as String? ?? '';
          return HeatmapDay.fromJson(date, m);
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      }
      return [];
    } catch (e) {
      debugPrint('[Analytics] heatmap parse error: $e');
      return [];
    }
  }

  void _check(Response r) {
    if (r.statusCode != 200) {
      throw ApiException(
        r.data['message'] as String? ?? 'Analytics request failed',
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
