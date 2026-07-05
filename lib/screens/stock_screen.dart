import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/stock_provider.dart';
import 'package:ice_cream_pos/screens/bulk_stock_screen.dart';

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
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Add Single Product',
                  icon: const Icon(Icons.add, color: Color(0xFF1E293B)),
                  onPressed: () => _showAddProductDialog(context, ref),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkStockScreen()));
                  },
                  icon: const Icon(Icons.playlist_add, size: 20),
                  label: const Text('Add Bulk Stock', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
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
                  subtitle: Text('Current Stock: ${product.displayStock}', style: TextStyle(fontSize: 18, color: product.stock <= product.minimumStock ? Colors.red : Colors.green)),
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
                        onPressed: () => _showAddStockDialog(context, ref, product),
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

  void _showAddStockDialog(BuildContext context, WidgetRef ref, Product product) {
    final controller = TextEditingController();
    final isBox = product.isBoxPiece;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock for ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBox) ...[
              Text(
                'Note: This is a Box & Piece item (1 Box = ${product.piecesPerBox} Pieces).', 
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller,
              decoration: InputDecoration(labelText: isBox ? 'Quantity of BOXES (use - to reduce)' : 'Quantity (use - to reduce)'),
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(controller.text);
              if (quantity != null && quantity != 0) {
                final stockToAdd = isBox ? quantity * product.piecesPerBox : quantity;
                ref.read(stockProvider.notifier).addStock(product.id!, stockToAdd);
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
  late TextEditingController _barcodeController;
  late TextEditingController _mrpController;
  late TextEditingController _discountController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  
  // UOM Controllers
  bool _isBoxPiece = false;
  late TextEditingController _piecesPerBoxController;
  late TextEditingController _boxBarcodeController;
  late TextEditingController _boxMrpController;
  late TextEditingController _boxDiscountController;
  late TextEditingController _boxPriceController;
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
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _mrpController = TextEditingController(text: widget.product?.mrp.toString() ?? '0.0');
    _discountController = TextEditingController(text: widget.product?.discount.toString() ?? '0.0');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '0.0');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '0');
    
    _isBoxPiece = widget.product?.isBoxPiece ?? false;
    _piecesPerBoxController = TextEditingController(text: widget.product?.piecesPerBox.toString() ?? '1');
    _boxBarcodeController = TextEditingController(text: widget.product?.boxBarcode ?? '');
    _boxMrpController = TextEditingController(text: widget.product?.boxMrp.toString() ?? '0.0');
    _boxDiscountController = TextEditingController(text: widget.product?.boxDiscount.toString() ?? '0.0');
    _boxPriceController = TextEditingController(text: widget.product?.boxPrice.toString() ?? '0.0');

    _mrpController.addListener(_updatePrice);
    _discountController.addListener(_updatePrice);
    _boxMrpController.addListener(_updateBoxPrice);
    _boxDiscountController.addListener(_updateBoxPrice);
    _selectedColor = widget.product?.color;
    
    if (widget.product != null) {
      _selectedCompany = widget.product!.company;
      _selectedType = widget.product!.type;
    }
  }

  void _updatePrice() {
    final mrp = double.tryParse(_mrpController.text) ?? 0.0;
    final discount = double.tryParse(_discountController.text) ?? 0.0;
    final price = mrp - discount;
    if (_priceController.text != price.toStringAsFixed(2)) {
      _priceController.text = price.toStringAsFixed(2);
    }
  }

  void _updateBoxPrice() {
    final mrp = double.tryParse(_boxMrpController.text) ?? 0.0;
    final discount = double.tryParse(_boxDiscountController.text) ?? 0.0;
    final price = mrp - discount;
    if (_boxPriceController.text != price.toStringAsFixed(2)) {
      _boxPriceController.text = price.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _mrpController.removeListener(_updatePrice);
    _discountController.removeListener(_updatePrice);
    _boxMrpController.removeListener(_updateBoxPrice);
    _boxDiscountController.removeListener(_updateBoxPrice);
    _nameController.dispose();
    _barcodeController.dispose();
    _mrpController.dispose();
    _discountController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _piecesPerBoxController.dispose();
    _boxBarcodeController.dispose();
    _boxMrpController.dispose();
    _boxDiscountController.dispose();
    _boxPriceController.dispose();
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: SwitchListTile(
                    title: const Text('Sold in Boxes & Pieces?', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Check this if this item comes in a box but can be sold individually.'),
                    value: _isBoxPiece,
                    onChanged: (val) {
                      setState(() {
                        _isBoxPiece = val;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Piece (Individual) Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    hintText: 'Click here and scan barcode',
                    suffixIcon: Icon(Icons.qr_code_scanner),
                  ),
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mrpController,
                        decoration: const InputDecoration(labelText: 'MRP'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Invalid MRP' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _discountController,
                        decoration: const InputDecoration(labelText: 'Discount'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Invalid Discount' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Net Amount (Selling Price)',
                    fillColor: Colors.black12,
                    filled: true,
                  ),
                  readOnly: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                
                if (_isBoxPiece) ...[
                  const SizedBox(height: 24),
                  const Text('Box (Unit) Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  TextFormField(
                    controller: _piecesPerBoxController,
                    decoration: const InputDecoration(labelText: 'Pieces per Box'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty || int.tryParse(v) == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _boxBarcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Box Barcode',
                      hintText: 'Enter box barcode or sub-product code',
                      suffixIcon: Icon(Icons.qr_code_scanner),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _boxMrpController,
                          decoration: const InputDecoration(labelText: 'Box MRP'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _boxDiscountController,
                          decoration: const InputDecoration(labelText: 'Box Discount'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _boxPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Box Net Amount (Selling Price)',
                      fillColor: Colors.black12,
                      filled: true,
                    ),
                    readOnly: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
                
                const SizedBox(height: 24),
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
                barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
                category: _selectedType, // We can just use the type or 'Ice Cream' as category for legacy reasons
                company: _selectedCompany,
                type: _selectedType,
                mrp: double.parse(_mrpController.text),
                discount: double.parse(_discountController.text),
                price: double.parse(_priceController.text),
                isBoxPiece: _isBoxPiece,
                piecesPerBox: int.tryParse(_piecesPerBoxController.text) ?? 1,
                boxBarcode: _boxBarcodeController.text.isEmpty ? null : _boxBarcodeController.text,
                boxMrp: double.tryParse(_boxMrpController.text) ?? 0.0,
                boxDiscount: double.tryParse(_boxDiscountController.text) ?? 0.0,
                boxPrice: double.tryParse(_boxPriceController.text) ?? 0.0,
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
