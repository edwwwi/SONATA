import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/cart_provider.dart';
import 'package:ice_cream_pos/providers/sales_provider.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productProvider);
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    return Row(
      children: [
        // Products Grid
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Products', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: productsState.when(
                    data: (products) {
                      if (products.isEmpty) {
                        return const Center(child: Text('No products available. Add products first.', style: TextStyle(fontSize: 20)));
                      }
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: product.stock > 0 ? () {
                                ref.read(cartProvider.notifier).addProduct(product);
                              } : null,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: product.imagePath != null && File(product.imagePath!).existsSync()
                                        ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                                        : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.icecream, size: 64, color: Colors.grey),
                                          ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.green)),
                                          Text('Stock: ${product.stock}', style: TextStyle(fontSize: 16, color: product.stock > 0 ? Colors.black54 : Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Cart Sidebar
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue,
                  width: double.infinity,
                  child: const Text('Current Bill', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Expanded(
                  child: cartItems.isEmpty
                      ? const Center(child: Text('Cart is empty', style: TextStyle(fontSize: 18)))
                      : ListView.builder(
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartItems[index];
                            return ListTile(
                              title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('\$${item.product.price.toStringAsFixed(2)} x ${item.quantity} = \$${item.totalPrice.toStringAsFixed(2)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => ref.read(cartProvider.notifier).decreaseQuantity(item.product),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 18)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      // Check if there is stock to add
                                      if (item.quantity < item.product.stock) {
                                        ref.read(cartProvider.notifier).addProduct(item.product);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock')));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: const Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: cartItems.isEmpty ? null : () {
                                ref.read(cartProvider.notifier).clearCart();
                              },
                              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: cartItems.isEmpty ? null : () async {
                                await ref.read(salesProvider.notifier).completeSale();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale Completed Successfully!', style: TextStyle(fontSize: 18))));
                                }
                              },
                              child: const Text('Complete Sale', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
