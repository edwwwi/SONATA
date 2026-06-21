import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/stock_provider.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      body: productsState.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products available.', style: TextStyle(fontSize: 20)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  subtitle: Text('Current Stock: ${product.stock}', style: TextStyle(fontSize: 18, color: product.stock < 10 ? Colors.red : Colors.green)),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _showAddStockDialog(context, ref, product.id!, product.name),
                    icon: const Icon(Icons.add_box),
                    label: const Text('Add Stock'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddStockDialog(BuildContext context, WidgetRef ref, int productId, String productName) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Stock for $productName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Quantity to Add'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity > 0) {
                ref.read(stockProvider.notifier).addStock(productId, quantity);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock Added Successfully')));
              }
            },
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }
}
