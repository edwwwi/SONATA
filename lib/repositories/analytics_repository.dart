import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ice_cream_pos/core/database.dart';
import 'package:intl/intl.dart';
import 'package:ice_cream_pos/models/heatmap_model.dart';

class MonthlyAnalyticsRepository {
  Future<Map<DateTime, DailySalesSummary>> getMonthlyHeatmapData(int year, int month) async {
    final db = await DatabaseHelper.instance.database;
    final yearStr = year.toString();
    final monthStr = month.toString().padLeft(2, '0');
    final queryMonth = '$yearStr-$monthStr';

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        date(s.created_at) as sale_date, 
        SUM(s.total_amount) as total_sales, 
        COUNT(DISTINCT s.id) as bill_count,
        SUM(si.quantity) as items_sold
      FROM sales s
      LEFT JOIN sale_items si ON s.id = si.sale_id
      WHERE strftime('%Y-%m', s.created_at) = ?
      GROUP BY date(s.created_at)
    ''', [queryMonth]);

    final Map<DateTime, DailySalesSummary> heatmapData = {};
    for (var row in results) {
      final summary = DailySalesSummary.fromMap(row);
      // Normalize to midnight
      heatmapData[DateTime(summary.date.year, summary.date.month, summary.date.day)] = summary;
    }

    return heatmapData;
  }

  Future<DailyDetailedStats?> getDailyDetailedStats(DateTime date) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        s.id as bill_id,
        s.total_amount,
        SUM(si.quantity) as total_items
      FROM sales s
      LEFT JOIN sale_items si ON s.id = si.sale_id
      WHERE date(s.created_at) = ?
      GROUP BY s.id
    ''', [dateStr]);

    if (results.isEmpty) {
      return null;
    }

    double totalSales = 0;
    int billCount = results.length;
    double highestBill = double.negativeInfinity;
    double lowestBill = double.infinity;
    int totalItemsSold = 0;

    for (var row in results) {
      final amount = (row['total_amount'] as num).toDouble();
      final items = (row['total_items'] as num?)?.toInt() ?? 0;
      
      totalSales += amount;
      totalItemsSold += items;
      if (amount > highestBill) highestBill = amount;
      if (amount < lowestBill) lowestBill = amount;
    }

    return DailyDetailedStats(
      date: date,
      totalSales: totalSales,
      billCount: billCount,
      averageBillValue: totalSales / billCount,
      highestBill: highestBill == double.negativeInfinity ? 0 : highestBill,
      lowestBill: lowestBill == double.infinity ? 0 : lowestBill,
      averageItemsPerBill: totalItemsSold / billCount,
    );
  }

  Future<List<TopSellingProduct>> getTopSellingProductsForDate(DateTime date) async {
    final db = await DatabaseHelper.instance.database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        p.name, 
        p.company,
        SUM(si.quantity) as quantity_sold, 
        SUM(si.quantity * si.price) as revenue
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      JOIN products p ON si.product_id = p.id
      WHERE date(s.created_at) = ?
      GROUP BY p.id
      ORDER BY quantity_sold DESC
      LIMIT 10
    ''', [dateStr]);

    return results.map((row) => TopSellingProduct.fromMap(row)).toList();
  }
}
