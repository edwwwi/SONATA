import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/analytics_provider.dart';
import 'package:intl/intl.dart';

class SalesHeatmapWidget extends ConsumerWidget {
  const SalesHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapState = ref.watch(salesHeatmapProvider);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Activity Heatmap',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Daily bill counts over the last year',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            heatmapState.when(
              loading: () => const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SizedBox(
                height: 150,
                child: Center(child: Text('Error loading heatmap: $error', style: const TextStyle(color: Colors.red))),
              ),
              data: (data) => _buildHeatmap(context, data),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context, Map<DateTime, int> data) {
    // Generate dates for the last 52 weeks (364 days)
    final now = DateTime.now();
    // We want the last column to end on today.
    // If today is weekday X (Monday=1, Sunday=7), we want to go back 51 weeks + X days.
    // To make it simple, let's just generate the last 364 days, ending today.
    final List<DateTime> dates = [];
    for (int i = 363; i >= 0; i--) {
      dates.add(now.subtract(Duration(days: i)));
    }

    // Maximum value to scale colors
    int maxCount = 1;
    if (data.isNotEmpty) {
      maxCount = data.values.reduce((a, b) => a > b ? a : b);
    }

    // GitHub heatmap groups by columns of 7 (one week per column).
    // The top row is day 0 (e.g., Sunday), bottom is day 6 (Saturday).
    // Because we just have 364 days ending today, the first day might be any day of the week.
    // We will just lay them out vertically: 7 rows, 52 columns.
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Auto-scroll to the right (latest)
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day labels
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Sun', style: TextStyle(fontSize: 10, color: Colors.grey)),
              SizedBox(height: 20),
              Text('Wed', style: TextStyle(fontSize: 10, color: Colors.grey)),
              SizedBox(height: 20),
              Text('Sat', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 8),
          // Heatmap grid
          SizedBox(
            height: 110,
            child: GridView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, // 7 days a week
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                // normalize date to ignore time
                final keyDate = DateTime(date.year, date.month, date.day);
                final count = data[keyDate] ?? 0;

                // Color scale logic (GitHub style greens)
                Color boxColor = Colors.grey.shade100;
                if (count > 0) {
                  final ratio = count / maxCount;
                  if (ratio > 0.75) boxColor = Colors.green.shade800;
                  else if (ratio > 0.5) boxColor = Colors.green.shade600;
                  else if (ratio > 0.25) boxColor = Colors.green.shade400;
                  else boxColor = Colors.green.shade200;
                }

                return Tooltip(
                  message: '${DateFormat('MMM d, yyyy').format(date)}: $count bills',
                  child: Container(
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
