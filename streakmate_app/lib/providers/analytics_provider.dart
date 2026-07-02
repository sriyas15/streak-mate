import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exception.dart';
import '../models/remote/analytics_model.dart';
import '../repositories/analytics_repository.dart';

enum AnalyticsPeriod { week, month }

class AnalyticsState {
  final AnalyticsPeriod period;
  final bool loading;
  final String? error;

  final AnalyticsOverview? overview;
  final WeeklySummary? weeklySummary;
  final List<CategoryPerformance> categories;
  final List<AnalyticsInsight> insights;
  final List<HeatmapDay> heatmap;

  const AnalyticsState({
    this.period = AnalyticsPeriod.week,
    this.loading = false,
    this.error,
    this.overview,
    this.weeklySummary,
    this.categories = const [],
    this.insights = const [],
    this.heatmap = const [],
  });

  AnalyticsState copyWith({
    AnalyticsPeriod? period,
    bool? loading,
    String? error,
    AnalyticsOverview? overview,
    WeeklySummary? weeklySummary,
    List<CategoryPerformance>? categories,
    List<AnalyticsInsight>? insights,
    List<HeatmapDay>? heatmap,
  }) =>
      AnalyticsState(
        period: period ?? this.period,
        loading: loading ?? this.loading,
        error: error,
        overview: overview ?? this.overview,
        weeklySummary: weeklySummary ?? this.weeklySummary,
        categories: categories ?? this.categories,
        insights: insights ?? this.insights,
        heatmap: heatmap ?? this.heatmap,
      );

  // ── Derived values used by UI ─────────────────────────────────
  String get motivationalHeading {
    final rate = overview?.consistencyRate ?? 0;
    if (rate >= 90) return "You're on fire! 🔥";
    if (rate >= 70) return "Great momentum! 💪";
    if (rate >= 50) return "Keep going! 🌱";
    return "Let's get back on track 💡";
  }

  String get motivationalSubtitle {
    final rate = overview?.consistencyRate ?? 0;
    if (rate >= 90) return "Keep the momentum going.";
    if (rate >= 70) return "You're doing really well.";
    if (rate >= 50) return "Every day counts.";
    return "Small steps lead to big changes.";
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier(this._repo) : super(const AnalyticsState());
  final AnalyticsRepository _repo;

  Future<void> loadAll() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final periodStr = state.period == AnalyticsPeriod.week ? 'week' : 'month';
      final year = DateTime.now().year;

      // Fetch all in parallel — non-fatal errors handled per-call
      final results = await Future.wait([
        _repo.getOverview(periodStr),
        _repo.getWeeklySummary(),
        _repo.getCategoryPerformance(periodStr),
        _repo.getInsights(),
        _repo.getHeatmap(year),
      ]);

      state = state.copyWith(
        loading: false,
        overview: results[0] as AnalyticsOverview,
        weeklySummary: results[1] as WeeklySummary,
        categories: results[2] as List<CategoryPerformance>,
        insights: results[3] as List<AnalyticsInsight>,
        heatmap: results[4] as List<HeatmapDay>,
      );
    } on ApiException catch (e) {
      debugPrint('[Analytics] loadAll error: ${e.message}');
      state = state.copyWith(loading: false, error: e.message);
    } catch (e) {
      debugPrint('[Analytics] unexpected: $e');
      state = state.copyWith(loading: false, error: 'Could not load analytics');
    }
  }

  Future<void> setPeriod(AnalyticsPeriod period) async {
    if (state.period == period) return;
    state = state.copyWith(period: period, loading: true, error: null);
    try {
      final periodStr = period == AnalyticsPeriod.week ? 'week' : 'month';
      final results = await Future.wait([
        _repo.getOverview(periodStr),
        _repo.getCategoryPerformance(periodStr),
      ]);
      state = state.copyWith(
        loading: false,
        overview: results[0] as AnalyticsOverview,
        categories: results[1] as List<CategoryPerformance>,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final analyticsRepositoryProvider =
    Provider<AnalyticsRepository>((ref) => AnalyticsRepository());

final analyticsProvider =
    StateNotifierProvider.autoDispose<AnalyticsNotifier, AnalyticsState>(
        (ref) => AnalyticsNotifier(ref.watch(analyticsRepositoryProvider)));