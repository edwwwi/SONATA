import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/repositories/analytics_repository.dart';
import 'package:ice_cream_pos/models/heatmap_model.dart';
import 'dart:async';

final monthlyAnalyticsRepositoryProvider = Provider((ref) => MonthlyAnalyticsRepository());

class MonthlyAnalyticsState {
  final int year;
  final int month;
  final AsyncValue<Map<DateTime, DailySalesSummary>> heatmapData;

  MonthlyAnalyticsState({
    required this.year,
    required this.month,
    required this.heatmapData,
  });

  MonthlyAnalyticsState copyWith({
    int? year,
    int? month,
    AsyncValue<Map<DateTime, DailySalesSummary>>? heatmapData,
  }) {
    return MonthlyAnalyticsState(
      year: year ?? this.year,
      month: month ?? this.month,
      heatmapData: heatmapData ?? this.heatmapData,
    );
  }
}

class MonthlyAnalyticsNotifier extends Notifier<MonthlyAnalyticsState> {
  @override
  MonthlyAnalyticsState build() {
    Future.microtask(() => _fetchData());
    return MonthlyAnalyticsState(
      year: DateTime.now().year,
      month: DateTime.now().month,
      heatmapData: const AsyncValue.loading(),
    );
  }

  void _fetchData() async {
    state = state.copyWith(heatmapData: const AsyncValue.loading());
    try {
      final repo = ref.read(monthlyAnalyticsRepositoryProvider);
      final data = await repo.getMonthlyHeatmapData(state.year, state.month);
      state = state.copyWith(heatmapData: AsyncValue.data(data));
    } catch (e, stackTrace) {
      state = state.copyWith(heatmapData: AsyncValue.error(e, stackTrace));
    }
  }

  void setMonth(int year, int month) {
    state = state.copyWith(year: year, month: month);
    _fetchData();
  }
  
  void nextMonth() {
    int nextYear = state.year;
    int nextMonth = state.month + 1;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }
    setMonth(nextYear, nextMonth);
  }

  void previousMonth() {
    int prevYear = state.year;
    int prevMonth = state.month - 1;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }
    setMonth(prevYear, prevMonth);
  }
}

final monthlyAnalyticsProvider = NotifierProvider<MonthlyAnalyticsNotifier, MonthlyAnalyticsState>(() {
  return MonthlyAnalyticsNotifier();
});
