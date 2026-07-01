import 'package:flutter/material.dart';
import 'package:ice_cream_pos/models/heatmap_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/analytics_provider.dart';

class HeatmapTileWidget extends ConsumerStatefulWidget {
  final DateTime date;
  final DailySalesSummary? summary;
  
  const HeatmapTileWidget({
    super.key,
    required this.date,
    this.summary,
  });

  @override
  ConsumerState<HeatmapTileWidget> createState() => _HeatmapTileWidgetState();
}

class _HeatmapTileWidgetState extends ConsumerState<HeatmapTileWidget> {
  bool _isHovered = false;

  Color _getHeatmapColor(double sales) {
    if (sales == 0) return const Color(0xFFF3F4F6);
    if (sales < 5000) return const Color(0xFFDFF6DD).withOpacity(0.2);
    if (sales < 10000) return const Color(0xFFA7E6A3).withOpacity(0.4);
    if (sales < 20000) return const Color(0xFF69C96B).withOpacity(0.6);
    if (sales < 30000) return const Color(0xFF2FA84F).withOpacity(0.8);
    return const Color(0xFF167A2F);
  }

  Color _getTextColor(double sales) {
    if (sales == 0) return Colors.grey.shade600;
    if (sales < 20000) return Colors.black;
    return Colors.white;
  }

  void _showDetailedStatsDialog() async {
    final repo = ref.read(monthlyAnalyticsRepositoryProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final stats = await repo.getDailyDetailedStats(widget.date);
      final topProducts = await repo.getTopSellingProductsForDate(widget.date);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        _buildDetailedDialog(stats, topProducts);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading stats: $e')));
      }
    }
  }

  void _buildDetailedDialog(DailyDetailedStats? stats, List<TopSellingProduct> topProducts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('dd MMMM yyyy').format(widget.date), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: stats == null
              ? const Text('No sales data for this date.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statCard('Total Sales', '₹${stats.totalSales.toStringAsFixed(0)}'),
                        _statCard('Bills', '${stats.billCount}'),
                        _statCard('Avg Bill', '₹${stats.averageBillValue.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statCard('Highest Bill', '₹${stats.highestBill.toStringAsFixed(0)}'),
                        _statCard('Lowest Bill', '₹${stats.lowestBill.toStringAsFixed(0)}'),
                        _statCard('Avg Items/Bill', stats.averageItemsPerBill.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Top Selling Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Divider(),
                    if (topProducts.isEmpty) const Text('No items sold.'),
                    ...topProducts.map((p) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(Icons.icecream, color: Colors.blue),
                          ),
                          title: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(p.companyName),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${p.quantitySold} Sold', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('₹${p.revenue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = widget.summary?.totalSales ?? 0.0;
    final color = _getHeatmapColor(sales);
    final textColor = _getTextColor(sales);

    Widget tile = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isHovered ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.date.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '₹${sales.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 10,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );

    if (sales > 0) {
      tile = Tooltip(
        message: '${DateFormat('dd MMMM yyyy').format(widget.date)}\nSales: ₹${sales.toStringAsFixed(0)}\nBills: ${widget.summary?.billCount ?? 0}\nItems: ${widget.summary?.itemsSold ?? 0}',
        textStyle: const TextStyle(color: Colors.white),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(4),
        ),
        child: tile,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        child: InkWell(
          onTap: sales > 0 ? _showDetailedDialog : null,
          borderRadius: BorderRadius.circular(12),
          child: tile,
        ),
      ),
    );
  }
  
  void _showDetailedDialog() {
      _showDetailedStatsDialog();
  }
}
