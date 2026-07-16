import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/auth_provider.dart';
import 'package:ice_cream_pos/providers/sales_provider.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';
import 'package:ice_cream_pos/models/sale.dart';
import 'package:ice_cream_pos/core/export_utils.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authProvider).value ?? false;

    if (!isAuthenticated) {
      return const _PinScreen();
    }

    return const _ReportsDashboard();
  }
}

class _PinScreen extends ConsumerStatefulWidget {
  const _PinScreen();

  @override
  ConsumerState<_PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<_PinScreen> {
  String _pin = '';

  void _onKeyPress(String value) {
    setState(() {
      if (value == '<') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_pin.length < 4) _pin += value;
      }
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    final success = await ref.read(authProvider.notifier).verifyPin(_pin);
    if (!success) {
      setState(() {
        _pin = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Enter Owner PIN',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _pin.length ? Colors.blue : Colors.grey[300],
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 300,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                for (var i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
                const SizedBox.shrink(),
                _buildKeypadButton('0'),
                _buildKeypadButton('<', color: Colors.red[100]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String value, {Color? color}) {
    return InkWell(
      onTap: () => _onKeyPress(value),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _ReportsDashboard extends ConsumerWidget {
  const _ReportsDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Reports Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Lock Reports',
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily Sales', icon: Icon(Icons.today)),
              Tab(text: 'Sales History', icon: Icon(Icons.history)),
              Tab(text: 'Stock Report', icon: Icon(Icons.inventory)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_DailySalesTab(), _SalesHistoryTab(), _StockReportTab()],
        ),
      ),
    );
  }
}

class _DailySalesTab extends ConsumerWidget {
  const _DailySalesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesState = ref.watch(salesProvider);

    return salesState.when(
      data: (sales) {
        final today = DateTime.now();
        final todaySales = sales
            .where(
              (s) =>
                  s.createdAt.year == today.year &&
                  s.createdAt.month == today.month &&
                  s.createdAt.day == today.day,
            )
            .toList();
        final totalPaidAmount = todaySales.where((s) => !s.isDue).fold(
          0.0,
          (sum, item) => sum + item.totalAmount,
        );
        final totalDueAmount = todaySales.where((s) => s.isDue).fold(
          0.0,
          (sum, item) => sum + item.totalAmount,
        );

        bool isProcessing = false;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${DateFormat('yyyy-MM-dd').format(today)}',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(
                    'Total Bills',
                    todaySales.length.toString(),
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Total Sales (Paid)',
                    '₹${totalPaidAmount.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Total Due',
                    '₹${totalDueAmount.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                ],
              ),
              const Spacer(),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isProcessing ? null : () async {
                          setState(() { isProcessing = true; });
                          try {
                            if (todaySales.isEmpty) throw Exception('No data available to export.');
                            final products = ref.read(productProvider).value ?? [];
                            await ExportUtils.exportDailyReportPdf(sales, products);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('PDF Exported')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            setState(() { isProcessing = false; });
                          }
                        },
                        icon: isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: isProcessing ? null : () async {
                          setState(() { isProcessing = true; });
                          try {
                            if (todaySales.isEmpty) throw Exception('No data available to export.');
                            await ExportUtils.exportSalesCsv(todaySales);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('CSV Exported')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            setState(() { isProcessing = false; });
                          }
                        },
                        icon: isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.table_chart),
                        label: const Text('Export CSV'),
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DB
class _SalesHistoryTab extends ConsumerWidget {
  const _SalesHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesState = ref.watch(salesProvider);

    return salesState.when(
      data: (sales) {
        if (sales.isEmpty) {
          return const Center(
            child: Text('No sales history.', style: TextStyle(fontSize: 20)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            return Card(
              color: sale.isDue ? Colors.red.shade50 : null,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: sale.isDue ? Colors.red.shade200 : Colors.transparent, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                onTap: () => _showBillDetails(context, ref, sale),
                leading: Icon(Icons.receipt_long, size: 40, color: sale.isDue ? Colors.red : null),
                title: Text(
                  'Bill: ${sale.billNumber} ${sale.isDue ? "(DUE: ${sale.dueName ?? 'Unknown'})" : ""}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: sale.isDue ? Colors.red.shade900 : null),
                ),
                subtitle: Text(
                  'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.createdAt)}',
                ),
                trailing: Text(
                  '₹${sale.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: sale.isDue ? Colors.red : Colors.green,
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _showBillDetails(BuildContext context, WidgetRef ref, Sale sale) async {
    final db = await ref.read(databaseProvider.future);
    final saleItemsMaps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [sale.id]);
    final products = ref.read(productProvider).value ?? [];

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bill Details: ${sale.billNumber}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: saleItemsMaps.length,
              itemBuilder: (context, index) {
                final item = saleItemsMaps[index];
                final productId = item['product_id'] as int;
                final quantity = item['quantity'] as int;
                final price = (item['price'] as num).toDouble();
                
                final product = products.where((p) => p.id == productId).firstOrNull;
                final productName = product?.name ?? 'Unknown Product';
                final company = product?.company ?? '';

                return ListTile(
                  title: Text('$company $productName', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Qty: $quantity  x  ₹${price.toStringAsFixed(2)}'),
                  trailing: Text('₹${(quantity * price).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                );
              },
            ),
          ),
          actions: [
            if (sale.isDue)
              TextButton.icon(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                label: const Text('Confirm Payment Received', style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  await ref.read(salesProvider.notifier).markBillAsPaid(sale.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Bill marked as paid!'),
                      backgroundColor: Colors.green,
                    ));
                  }
                },
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      }
    );
  }
}

class _StockReportTab extends ConsumerWidget {
  const _StockReportTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productProvider);

    return productsState.when(
      data: (products) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        if (products.isEmpty) throw Exception('No data available to export.');
                        await ExportUtils.exportStockCsv(products);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Stock CSV Exported')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Export Failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export Stock CSV'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Sno.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Company Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Net Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: products.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      return DataRow(cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(product.company)),
                        DataCell(Text(product.name)),
                        DataCell(
                          Text(product.displayStock, 
                            style: TextStyle(
                              color: product.stock <= product.minimumStock ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold
                            )
                          )
                        ),
                        DataCell(Text('₹${product.mrp.toStringAsFixed(2)}')),
                        DataCell(Text('₹${product.discount.toStringAsFixed(2)}')),
                        DataCell(Text('₹${product.price.toStringAsFixed(2)}')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
