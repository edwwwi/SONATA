import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/stock_provider.dart';
import 'package:ice_cream_pos/core/export_utils.dart';
import 'package:intl/intl.dart';

class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({super.key});

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  void _pickDateRange() async {
    final initialDateRange = _selectedDateRange ?? 
        DateTimeRange(start: DateTime.now().subtract(const Duration(days: 7)), end: DateTime.now());
        
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
    );

    if (newRange != null) {
      setState(() {
        _selectedDateRange = newRange;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockState = ref.watch(stockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          stockState.when(
            data: (movements) => Row(
              children: [
                IconButton(
                  tooltip: 'Export CSV',
                  icon: const Icon(Icons.file_download),
                  onPressed: () => ExportUtils.exportStockMovementsCsv(movements),
                ),
                IconButton(
                  tooltip: 'Export PDF',
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => ExportUtils.exportStockMovementsPdf(movements),
                ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          )
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search product...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _selectedDateRange == null 
                        ? 'Filter by Date' 
                        : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}'
                  ),
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                  ),
                ]
              ],
            ),
          ),
          
          // Data Table
          Expanded(
            child: stockState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (movements) {
                // Apply filters
                var filteredMovements = movements.where((m) {
                  final matchesSearch = m.productName.toLowerCase().contains(_searchQuery);
                  bool matchesDate = true;
                  if (_selectedDateRange != null) {
                    final d = m.createdAt;
                    final start = _selectedDateRange!.start;
                    final end = _selectedDateRange!.end.add(const Duration(days: 1)); // Include end day fully
                    matchesDate = d.isAfter(start) && d.isBefore(end);
                  }
                  return matchesSearch && matchesDate;
                }).toList();

                if (filteredMovements.isEmpty) {
                  return const Center(child: Text('No stock movements found.'));
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                      columns: const [
                        DataColumn(label: Text('Date & Time')),
                        DataColumn(label: Text('Product')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Prev Stock')),
                        DataColumn(label: Text('Curr Stock')),
                        DataColumn(label: Text('Remarks')),
                      ],
                      rows: filteredMovements.map((m) {
                        return DataRow(
                          cells: [
                            DataCell(Text(DateFormat('dd MMM yyyy HH:mm').format(m.createdAt))),
                            DataCell(Text(m.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: m.movementType == 'SALE' ? Colors.red[50] : Colors.green[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  m.movementType,
                                  style: TextStyle(
                                    color: m.movementType == 'SALE' ? Colors.red : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                m.quantity > 0 ? '+${m.quantity}' : m.quantity.toString(),
                                style: TextStyle(
                                  color: m.quantity > 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(m.previousStock.toString())),
                            DataCell(Text(m.currentStock.toString())),
                            DataCell(Text(m.remarks ?? '-')),
                          ],
                        );
                      }).toList(),
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
