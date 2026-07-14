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
      final periodStr =
          state.period == AnalyticsPeriod.week ? 'week' : 'month';
      final year = DateTime.now().year;

      AnalyticsOverview? overview;
      WeeklySummary? weeklySummary;
      List<CategoryPerformance> categories = [];
      List<AnalyticsInsight> insights = [];
      List<HeatmapDay> heatmap = [];

      // Run independently — one failure won't block others
      final results = await Future.wait([
        _repo.getOverview(periodStr).then<AnalyticsOverview?>((v) => v)
            .onError((e, _) { debugPrint('[Analytics] overview failed: $e'); return null; }),
        _repo.getWeeklySummary().then<WeeklySummary?>((v) => v)
            .onError((e, _) { debugPrint('[Analytics] weeklySummary failed: $e'); return null; }),
        _repo.getCategoryPerformance(periodStr).then<List<CategoryPerformance>>((v) => v)
            .onError((e, _) { debugPrint('[Analytics] categories failed: $e'); return []; }),
        _repo.getInsights().then<List<AnalyticsInsight>>((v) => v)
            .onError((e, _) { debugPrint('[Analytics] insights failed: $e'); return []; }),
        _repo.getHeatmap(year).then<List<HeatmapDay>>((v) => v)
            .onError((e, _) { debugPrint('[Analytics] heatmap failed: $e'); return []; }),
      ]);

      overview = results[0] as AnalyticsOverview?;
      weeklySummary = results[1] as WeeklySummary?;
      categories = results[2] as List<CategoryPerformance>;
      insights = results[3] as List<AnalyticsInsight>;
      heatmap = results[4] as List<HeatmapDay>;

      state = state.copyWith(
        loading: false,
        overview: overview,
        weeklySummary: weeklySummary,
        categories: categories,
        insights: insights,
        heatmap: heatmap,
      );
    } catch (e) {
      debugPrint('[Analytics] loadAll unexpected: $e');
      state = state.copyWith(
          loading: false, error: 'Could not load analytics');
    }
  }

  Future<void> setPeriod(AnalyticsPeriod period) async {
    if (state.period == period) return;
    state = state.copyWith(period: period, loading: true, error: null);
    try {
      final periodStr = period == AnalyticsPeriod.week ? 'week' : 'month';
      AnalyticsOverview? overview;
      List<CategoryPerformance> categories = [];

      await Future.wait([
        _repo.getOverview(periodStr).then((v) => overview = v).catchError((e) {
          debugPrint('[Analytics] setPeriod overview failed: $e');
        }),
        _repo.getCategoryPerformance(periodStr).then((v) => categories = v).catchError((e) {
          debugPrint('[Analytics] setPeriod categories failed: $e');
        }),
      ]);

      state = state.copyWith(
        loading: false,
        overview: overview ?? state.overview,
        categories: categories.isNotEmpty ? categories : state.categories,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Could not update period');
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final analyticsRepositoryProvider =
    Provider<AnalyticsRepository>((ref) => AnalyticsRepository());

final analyticsProvider =
    StateNotifierProvider.autoDispose<AnalyticsNotifier, AnalyticsState>(
        (ref) => AnalyticsNotifier(ref.watch(analyticsRepositoryProvider)));
