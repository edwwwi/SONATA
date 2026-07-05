import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/stock_provider.dart';

class BulkStockItem {
  final Product product;
  final TextEditingController quantityController;

  BulkStockItem({required this.product})
      : quantityController = TextEditingController(text: '1');
}

class BulkStockScreen extends ConsumerStatefulWidget {
  const BulkStockScreen({super.key});

  @override
  ConsumerState<BulkStockScreen> createState() => _BulkStockScreenState();
}

class _BulkStockScreenState extends ConsumerState<BulkStockScreen> {
  final List<BulkStockItem> _items = [];
  bool _isSubmitting = false;
  TextEditingController? _searchController;

  void _submitBulkStock() async {
    if (_items.isEmpty) return;
    
    // Validate quantities
    for (var item in _items) {
      if (int.tryParse(item.quantityController.text) == null || int.parse(item.quantityController.text) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid quantities (> 0) for all items.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final List<Map<String, dynamic>> submitData = _items.map((item) {
        return {
          'productId': item.product.id,
          'quantity': int.parse(item.quantityController.text),
        };
      }).toList();

      await ref.read(stockProvider.notifier).addBulkStock(submitData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulk stock added successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding bulk stock: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.quantityController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bulk Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : _submitBulkStock,
                icon: _isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Confirm & Add'),
              ),
            )
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: productsState.when(
        data: (products) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Autocomplete<Product>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Product>.empty();
                      }
                      return products.where((Product p) {
                        final searchLower = textEditingValue.text.toLowerCase();
                        return p.name.toLowerCase().contains(searchLower) ||
                               p.company.toLowerCase().contains(searchLower) ||
                               (p.barcode?.toLowerCase().contains(searchLower) ?? false);
                      });
                    },
                    displayStringForOption: (Product option) => '${option.company} ${option.name}',
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      _searchController = textEditingController;
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Search for a product to add...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    onSelected: (Product selection) {
                      // Add to list if not already there
                      if (!_items.any((item) => item.product.id == selection.id)) {
                        setState(() {
                          _items.add(BulkStockItem(product: selection));
                        });
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Product already in the list.')),
                         );
                      }
                      
                      // Clear the search box for the next item using post frame callback 
                      // to avoid conflict with Autocomplete internal state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _searchController?.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                if (_items.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Search and select products to add stock.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final p = item.product;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${p.company} ${p.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      Text('Current Stock: ${p.displayStock}', style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: item.quantityController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: p.isBoxPiece ? 'Quantity (Boxes)' : 'Quantity (Units)',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _items.removeAt(index);
                                    });
                                  },
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading products: $e')),
      ),
    );
  }
}
