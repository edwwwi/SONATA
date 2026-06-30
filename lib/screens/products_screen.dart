import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showAddProductDialog(context, ref),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
      body: productsState.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products. Click "Add Product" to create one.', style: TextStyle(fontSize: 20)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final isOutOfStock = product.stock <= 0;
              // Mocking a last added date for the UI
              final mockDate = DateTime.now().subtract(Duration(days: index * 2 + 1));
              final formattedDate = '${mockDate.day}/${mockDate.month}/${mockDate.year} at ${mockDate.hour}:${mockDate.minute.toString().padLeft(2, '0')}';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: product.color != null
                            ? Container(color: Color(product.color!))
                            : const Icon(Icons.icecream, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Category: ${product.category}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.update, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Last stock added: $formattedDate',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Stock Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isOutOfStock ? Colors.red.shade100 : Colors.green.shade100),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${product.stock}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isOutOfStock ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'In Stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOutOfStock ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
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
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(productProvider.notifier).deleteProduct(product.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, {Product? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AddProductDialog(product: product),
    );
  }
}

class _AddProductDialog extends ConsumerStatefulWidget {
  final Product? product;
  const _AddProductDialog({this.product});

  @override
  ConsumerState<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends ConsumerState<_AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  int? _selectedColor;
  final List<Color> _availableColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? 'Ice Cream');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '0');
    _selectedColor = widget.product?.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add New Product' : 'Edit Product'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select Product Color', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableColors.map((color) {
                    final isSelected = _selectedColor == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color.toARGB32();
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                          boxShadow: [
                            if (isSelected) BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)
                          ],
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Category (e.g. Ice Cream, Drinks)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Enter valid price' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Initial Stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty || int.tryParse(v) == null ? 'Enter valid stock' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontSize: 18))),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final product = Product(
                id: widget.product?.id,
                name: _nameController.text,
                category: _categoryController.text,
                price: double.parse(_priceController.text),
                stock: int.parse(_stockController.text),
                color: _selectedColor,
              );

              if (widget.product == null) {
                ref.read(productProvider.notifier).addProduct(product);
              } else {
                ref.read(productProvider.notifier).updateProduct(product);
              }
              Navigator.pop(context);
            }
          },
          child: const Text('Save', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
