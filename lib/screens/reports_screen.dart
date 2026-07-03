import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/auth_provider.dart';
import 'package:ice_cream_pos/providers/sales_provider.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
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
    final productsState = ref.watch(productProvider);

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
        final totalAmount = todaySales.fold(
          0.0,
          (sum, item) => sum + item.totalAmount,
        );

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
                    'Total Sales',
                    '₹${totalAmount.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final products = ref.read(productProvider).value ?? [];
                      await ExportUtils.exportDailyReportPdf(sales, products);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PDF Exported')),
                        );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await ExportUtils.exportSalesCsv(todaySales);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('CSV Exported')),
                        );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export CSV'),
                  ),
                ],
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
              child: ListTile(
                leading: const Icon(Icons.receipt_long, size: 40),
                title: Text(
                  'Bill: ${sale.billNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.createdAt)}',
                ),
                trailing: Text(
                  '₹${sale.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
                      await ExportUtils.exportStockCsv(products);
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Stock CSV Exported')),
                        );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export Stock CSV'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Category: ${product.category}'),
                      trailing: Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: product.stock < 10 ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  );
                },
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
