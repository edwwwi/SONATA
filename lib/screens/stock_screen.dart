import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';
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
                  onTap: () => _showAddProductDialog(context, ref, product),
                  contentPadding: const EdgeInsets.all(16),
                  title: Text('${product.company} ${product.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  subtitle: Text('Current Stock: ${product.stock}', style: TextStyle(fontSize: 18, color: product.stock < 10 ? Colors.red : Colors.green)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Product',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Product'),
                              content: Text('Are you sure you want to delete ${product.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    ref.read(productProvider.notifier).deleteProduct(product.id!);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddStockDialog(context, ref, product.id!, product.name),
                        icon: const Icon(Icons.add_box),
                        label: const Text('Adjust Stock'),
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

  void _showAddStockDialog(BuildContext context, WidgetRef ref, int productId, String productName) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock for $productName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Quantity (use - to reduce)'),
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity != 0) {
                ref.read(stockProvider.notifier).addStock(productId, quantity);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(quantity > 0 ? 'Stock Added Successfully' : 'Stock Reduced Successfully')));
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, WidgetRef ref, [Product? product]) {
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
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  String _selectedCompany = 'Sonata';
  String _selectedType = 'Ice Cream';
  final List<String> _companies = ['Sonata', 'Amul', 'Merceleys', 'Arun', 'Camery', 'Other'];
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
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '0');
    _selectedColor = widget.product?.color;
    
    if (widget.product != null) {
      _selectedCompany = widget.product!.company;
      _selectedType = widget.product!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                DropdownButtonFormField<String>(
                  value: _selectedCompany,
                  decoration: const InputDecoration(labelText: 'Company'),
                  items: _companies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCompany = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Product Type', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Ice Cream'),
                        value: 'Ice Cream',
                        groupValue: _selectedType,
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Soft Drinks'),
                        value: 'Soft Drinks',
                        groupValue: _selectedType,
                        onChanged: (val) => setState(() => _selectedType = val!),
                      ),
                    ),
                  ],
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
        if (widget.product != null)
          TextButton(
            onPressed: () => _confirmDeleteWithText(context, ref, widget.product!),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 18)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontSize: 18))),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final product = Product(
                id: widget.product?.id,
                name: _nameController.text,
                category: _selectedType, // We can just use the type or 'Ice Cream' as category for legacy reasons
                company: _selectedCompany,
                type: _selectedType,
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

  void _confirmDeleteWithText(BuildContext context, WidgetRef ref, Product product) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To delete ${product.name}, please type DELETE below.'),
            const SizedBox(height: 16),
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Type DELETE')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (controller.text == 'DELETE') {
                ref.read(productProvider.notifier).deleteProduct(product.id!);
                Navigator.pop(context);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please type exactly DELETE')));
              }
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
