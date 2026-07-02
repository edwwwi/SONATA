import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/analytics_provider.dart';
import 'package:ice_cream_pos/widgets/analytics/heatmap_tile_widget.dart';
import 'package:intl/intl.dart';

class SalesHeatmapWidget extends ConsumerWidget {
  const SalesHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monthlyAnalyticsProvider);
    final notifier = ref.read(monthlyAnalyticsProvider.notifier);
    final monthDate = DateTime(state.year, state.month, 1);
    final monthLabel = DateFormat('MMMM yyyy').format(monthDate);

    return Column(
      children: [
        // Top: Calendar Card
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header: Month Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Sales Heatmap', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: notifier.previousMonth,
                        ),
                        Text(
                          monthLabel,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            final now = DateTime.now();
                            if (state.year < now.year || (state.year == now.year && state.month < now.month)) {
                              notifier.nextMonth();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Calendar Days Header
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                            .map((day) => Expanded(
                                  child: Center(
                                    child: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),

                      // Calendar Grid
                      state.heatmapData.when(
                        loading: () => const SizedBox(
                          height: 300,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, s) => const SizedBox(height: 300),
                        data: (data) {
                          final daysInMonth = DateUtils.getDaysInMonth(state.year, state.month);
                          int startWeekday = monthDate.weekday;
                          if (startWeekday == 7) startWeekday = 0; // Sunday is 0

                          List<Widget> tiles = List.generate(startWeekday, (index) => const SizedBox());

                          for (int i = 1; i <= daysInMonth; i++) {
                            final date = DateTime(state.year, state.month, i);
                            final summary = data[date];
                            tiles.add(HeatmapTileWidget(date: date, summary: summary));
                          }

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1.0, // Perfect Square
                            children: tiles,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legend
                const Center(
                  child: Wrap(
                    spacing: 12,
                    children: [
                      Text('Legend:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                      _LegendItem(color: Color(0xFFEBEDF0), label: '0'),
                      _LegendItem(color: Color(0xFF9BE9A8), label: '₹1-5k'),
                      _LegendItem(color: Color(0xFF40C463), label: '₹5k-10k'),
                      _LegendItem(color: Color(0xFF30A14E), label: '₹10k-20k'),
                      _LegendItem(color: Color(0xFF216E39), label: '₹20k+'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
        
        const SizedBox(height: 24),
        
        // Bottom: Monthly Stats Row
        state.heatmapData.when(
          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
          error: (e, s) => SizedBox(height: 80, child: Center(child: Text('Error: $e'))),
          data: (data) {
            double totalSales = 0;
            num totalBills = 0;
            double highestDay = 0;
            int daysWithSales = 0;

            for (var summary in data.values) {
              totalSales += summary.totalSales;
              totalBills += summary.billCount;
              if (summary.totalSales > highestDay) highestDay = summary.totalSales;
              if (summary.totalSales > 0) daysWithSales++;
            }

            double avgDaily = daysWithSales > 0 ? totalSales / daysWithSales : 0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statHeaderCard('Total Sales', '₹${totalSales.toStringAsFixed(0)}'),
                const SizedBox(width: 16),
                _statHeaderCard('Total Bills', '$totalBills'),
                const SizedBox(width: 16),
                _statHeaderCard('Avg Daily Sales', '₹${avgDaily.toStringAsFixed(0)}'),
                const SizedBox(width: 16),
                _statHeaderCard('Highest Day', '₹${highestDay.toStringAsFixed(0)}'),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _statHeaderCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
