import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/cart_provider.dart';
import 'package:ice_cream_pos/providers/sales_provider.dart';
import 'package:ice_cream_pos/models/product.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _categories = [
    'All',
    'Sonata',
    'Amul',
    'Merceleys',
    'Arun',
    'Camery',
    'Soft Drinks',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Keep focus so we can always type/scan into search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String value, List<Product> products) {
    if (value.trim().isEmpty) {
      _focusNode.requestFocus();
      return;
    }
    
    // Check if the input perfectly matches a barcode or box barcode
    final matchedPiece = products.where((p) => p.barcode == value.trim()).firstOrNull;
    final matchedBox = products.where((p) => p.isBoxPiece && p.boxBarcode == value.trim()).firstOrNull;
    
    if (matchedPiece != null) {
      if (matchedPiece.stock > 0) {
        ref.read(cartProvider.notifier).addProduct(matchedPiece, isBoxSale: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product is out of stock!'), duration: Duration(seconds: 1)),
        );
      }
    } else if (matchedBox != null) {
      if (matchedBox.stock >= matchedBox.piecesPerBox) {
        ref.read(cartProvider.notifier).addProduct(matchedBox, isBoxSale: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Not enough pieces in stock for a full box! (${matchedBox.stock} left)'), duration: const Duration(seconds: 1)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barcode not found: ${value.trim()}'), duration: const Duration(seconds: 1)),
      );
    }
    
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _focusNode.requestFocus();
  }


  void _showCheckoutModal(BuildContext context, List<dynamic> cartItems, double subtotal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDue = false;
        bool isProcessing = false;
        final nameController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            final now = DateTime.now();
            final formattedDate = DateFormat('yyyy-MM-dd').format(now);
            final formattedTime = DateFormat('HH:mm').format(now);

            return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FINAL BILL',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                const Text('Sonata Ice Cream', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const Divider(height: 32, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: $formattedDate', style: const TextStyle(color: Colors.black54)),
                    Text('Time: $formattedTime', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                                  '${item.product.company} ${item.product.name} x${item.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                            Text(
                              '₹${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(height: 32, thickness: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isDue,
                      onChanged: (val) {
                        setState(() {
                          isDue = val ?? false;
                        });
                      },
                      activeColor: Colors.red,
                    ),
                    const Text('Mark as Due Bill (Credit)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                if (isDue)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Customer Name (Required for Due Bill)',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Go back
                        },
                        child: const Text('Add More', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDue ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isProcessing ? null : () async {
                          if (isDue && nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a customer name for the Due Bill.')));
                            return;
                          }
                          
                          setState(() { isProcessing = true; });
                          
                          try {
                            await ref.read(salesProvider.notifier).completeSale(
                              isDue: isDue, 
                              dueName: isDue ? nameController.text.trim() : null
                            );
                            if (context.mounted) {
                              Navigator.pop(context); // Close modal
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(isDue ? 'Due Bill Created!' : 'Sale Completed Successfully!'),
                                backgroundColor: isDue ? Colors.red : Colors.green,
                              ));
                              _focusNode.requestFocus();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() { isProcessing = false; });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Transaction Failed: $e'),
                                backgroundColor: Colors.red,
                              ));
                            }
                          }
                        },
                        child: isProcessing 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isDue ? 'Checkout as Due' : 'Checkout', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
    ).then((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productProvider);
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(_focusNode);
      },
      behavior: HitTestBehavior.translucent,
      child: Row(
        children: [
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          ref.invalidate(productProvider);
                          _focusNode.requestFocus();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.refresh, size: 20, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('EEEE, d MMM yyyy \'at\' hh:mm:ss a').format(DateTime.now()),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Dish Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Spacer(),
                          SizedBox(
                            width: 250,
                            height: 36,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search Menu',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              onSubmitted: (val) {
                                if (productsState.hasValue) {
                                  _onSearchSubmitted(val, productsState.value!);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                  _focusNode.requestFocus();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF1E293B) : Colors.white,
                                    border: Border.all(color: isSelected ? const Color(0xFF1E293B) : Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(category, style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13
                                      )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: productsState.when(
                      data: (products) {
                        var filtered = products.where((p) {
                          final isSearching = _searchQuery.trim().isNotEmpty;
                          final matchesCategory = isSearching || _selectedCategory == 'All' || 
                                                  p.company == _selectedCategory || 
                                                  p.type == _selectedCategory ||
                                                  p.category == _selectedCategory;
                          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                                (p.barcode != null && p.barcode!.contains(_searchQuery));
                          return matchesCategory && matchesSearch;
                        }).toList();

                        // Sort products without barcodes first
                        filtered.sort((a, b) {
                          final aHasBarcode = a.barcode != null && a.barcode!.trim().isNotEmpty;
                          final bHasBarcode = b.barcode != null && b.barcode!.trim().isNotEmpty;
                          if (aHasBarcode == bHasBarcode) return 0;
                          if (!aHasBarcode) return -1; // a comes first
                          return 1; // b comes first
                        });

                        if (filtered.isEmpty) {
                          return const Center(child: Text('No products found.', style: TextStyle(fontSize: 18, color: Colors.grey)));
                        }

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            final cartItem = cartItems.where((item) => item.product.id == product.id).firstOrNull;
                            final inCart = cartItem != null;
                            final isOutOfStock = product.stock <= 0;

                            return Opacity(
                              opacity: isOutOfStock ? 0.2 : 1.0,
                              child: Card(
                                elevation: 3,
                                shadowColor: Colors.black.withValues(alpha: 0.4),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                onTap: (!isOutOfStock && !inCart) ? () {
                                  if (product.isBoxPiece && product.piecesPerBox > 1) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text('Add ${product.name}'),
                                        content: const Text('Do you want to add a single piece or a full unit (box)?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              ref.read(cartProvider.notifier).addProduct(product, isBoxSale: false);
                                              _focusNode.requestFocus();
                                            },
                                            child: const Text('1 Piece (Nos)', style: TextStyle(fontSize: 16)),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              if (product.stock >= product.piecesPerBox) {
                                                ref.read(cartProvider.notifier).addProduct(product, isBoxSale: true);
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough pieces for a full unit! (${product.stock} left)')));
                                              }
                                              _focusNode.requestFocus();
                                            },
                                            child: const Text('1 Unit (Box)', style: TextStyle(fontSize: 16)),
                                          ),
                                        ],
                                      )
                                    );
                                  } else {
                                    ref.read(cartProvider.notifier).addProduct(product);
                                    _focusNode.requestFocus();
                                  }
                                } : null,
                                child: Stack(
                                  children: [
                                    Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: product.color != null
                                            ? Container(color: Color(product.color!))
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.icecream, size: 48, color: Colors.grey),
                                              ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${product.company} ${product.name}',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                product.type,
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                                              ),
                                              const Spacer(),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '₹${product.price.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isOutOfStock ? Colors.red : Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isOutOfStock ? 'Not Available' : 'Available',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                    if (inCart)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.15),
                                            border: Border.all(color: Colors.green, width: 2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                                        ),
                                      ),
                                  ],
                                ),
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
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 400,
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('#B12309', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: cartItems.isEmpty
                    ? Center(
                        child: Text('Cart is empty', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: cartItems.length,
                        separatorBuilder: (context, index) => const Divider(height: 32),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: item.product.color != null
                                    ? Container(color: Color(item.product.color!))
                                    : const Icon(Icons.image, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.displayName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => ref.read(cartProvider.notifier).decreaseQuantity(item.product, isBoxSale: item.isBoxSale),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                                child: const Icon(Icons.remove, size: 16),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () {
                                                final stockNeeded = item.isBoxSale ? (item.quantity + 1) * item.product.piecesPerBox : (item.quantity + 1);
                                                if (stockNeeded <= item.product.stock) {
                                                  ref.read(cartProvider.notifier).increaseQuantity(item.product, isBoxSale: item.isBoxSale);
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                                child: const Icon(Icons.add, size: 16),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            InkWell(
                                              onTap: () => ref.read(cartProvider.notifier).removeProduct(item.product, isBoxSale: item.isBoxSale),
                                              child: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    _buildTotalRow('Total Payment', '₹${subtotal.toStringAsFixed(2)}', isBold: true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 4,
                          shadowColor: Colors.green.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: cartItems.isEmpty ? null : () {
                          _showCheckoutModal(context, cartItems, subtotal);
                        },
                        child: const Text(
                          'Confirm Payment',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildTotalRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 14 : 13, color: isBold ? Colors.black : Colors.grey[700])),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.bold, fontSize: isBold ? 14 : 13, color: color ?? Colors.black)),
      ],
    );
  }


}
