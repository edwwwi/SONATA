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
    if (sales == 0) return const Color(0xFFEBEDF0);
    if (sales < 5000) return const Color(0xFF9BE9A8);
    if (sales < 10000) return const Color(0xFF40C463);
    if (sales < 20000) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  Color _getTextColor(double sales) {
    if (sales == 0) return Colors.grey.shade400;
    if (sales < 10000) return Colors.black87;
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
  void _buildDetailedDialog(DailyDetailedStats? stats, List<TopSellingProduct> topProducts) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Sales Report', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(DateFormat('dd MMMM yyyy').format(widget.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              if (stats == null)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('No sales data recorded for this date.', style: TextStyle(color: Colors.grey, fontSize: 16))),
                )
              else ...[
                // Stats Grid
                Row(
                  children: [
                    Expanded(child: _statCard('Total Sales', '₹${stats.totalSales.toStringAsFixed(0)}', isHighlight: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard('Total Bills', '${stats.billCount}')),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard('Avg Bill', '₹${stats.averageBillValue.toStringAsFixed(0)}')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _statCard('Highest Bill', '₹${stats.highestBill.toStringAsFixed(0)}')),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard('Lowest Bill', '₹${stats.lowestBill.toStringAsFixed(0)}')),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard('Items/Bill', stats.averageItemsPerBill.toStringAsFixed(1))),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Top Products
                const Text('Top Selling Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 12),
                if (topProducts.isEmpty)
                  const Text('No items sold.', style: TextStyle(color: Colors.grey))
                else
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: topProducts.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final p = topProducts[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.icecream, color: Colors.green.shade600, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(p.companyName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${p.revenue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('${p.quantitySold} Sold', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.green.shade50 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isHighlight ? Colors.green.shade200 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isHighlight ? Colors.green.shade700 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isHighlight ? Colors.green.shade900 : Colors.black87)),
        ],
      ),
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
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.date.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: textColor,
              ),
            ),
            if (sales > 0)
              Text(
                '₹${sales.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.9),
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
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0, _isHovered ? 1.05 : 1.0, 1.0),
        child: InkWell(
          onTap: sales > 0 ? _showDetailedDialog : null,
          borderRadius: BorderRadius.circular(4),
          child: tile,
        ),
      ),
    );
  }
  
  void _showDetailedDialog() {
      _showDetailedStatsDialog();
  }
}
