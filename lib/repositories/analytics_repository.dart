import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ice_cream_pos/core/database.dart';
import 'package:intl/intl.dart';

class AnalyticsRepository {
  Future<Map<DateTime, int>> getSalesHeatMapData() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    // Get sales for the last 365 days
    final startDate = now.subtract(const Duration(days: 365));
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        date(created_at) as sale_date, 
        COUNT(id) as bill_count
      FROM sales
      WHERE created_at >= ?
      GROUP BY date(created_at)
    ''', [startDateStr]);

    final Map<DateTime, int> heatmapData = {};
    for (var row in results) {
      final dateStr = row['sale_date'] as String;
      final count = row['bill_count'] as int;
      final date = DateTime.parse(dateStr);
      // Ensure we only store the date part for heatmap matching
      heatmapData[DateTime(date.year, date.month, date.day)] = count;
    }

    return heatmapData;
  }
}
