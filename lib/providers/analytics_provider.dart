import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider((ref) => AnalyticsRepository());

final salesHeatmapProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  final repo = ref.read(analyticsRepositoryProvider);
  return await repo.getSalesHeatMapData();
});
