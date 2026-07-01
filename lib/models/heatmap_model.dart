class DailySalesSummary {
  final DateTime date;
  final double totalSales;
  final int billCount;
  final int itemsSold;

  DailySalesSummary({
    required this.date,
    required this.totalSales,
    required this.billCount,
    required this.itemsSold,
  });

  factory DailySalesSummary.fromMap(Map<String, dynamic> map) {
    return DailySalesSummary(
      date: DateTime.parse(map['sale_date']),
      totalSales: map['total_sales']?.toDouble() ?? 0.0,
      billCount: map['bill_count'] ?? 0,
      itemsSold: map['items_sold'] ?? 0,
    );
  }
}

class DailyDetailedStats {
  final DateTime date;
  final double totalSales;
  final int billCount;
  final double averageBillValue;
  final double highestBill;
  final double lowestBill;
  final double averageItemsPerBill;

  DailyDetailedStats({
    required this.date,
    required this.totalSales,
    required this.billCount,
    required this.averageBillValue,
    required this.highestBill,
    required this.lowestBill,
    required this.averageItemsPerBill,
  });
}

class TopSellingProduct {
  final String productName;
  final String companyName;
  final int quantitySold;
  final double revenue;

  TopSellingProduct({
    required this.productName,
    required this.companyName,
    required this.quantitySold,
    required this.revenue,
  });

  factory TopSellingProduct.fromMap(Map<String, dynamic> map) {
    return TopSellingProduct(
      productName: map['name'] ?? 'Unknown',
      companyName: map['company'] ?? 'Unknown',
      quantitySold: map['quantity_sold'] ?? 0,
      revenue: map['revenue']?.toDouble() ?? 0.0,
    );
  }
}
