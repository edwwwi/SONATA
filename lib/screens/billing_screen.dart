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
    if (value.trim().isEmpty) return;
    
    // Check if the input perfectly matches a barcode
    final matchedProduct = products.where((p) => p.barcode == value.trim()).firstOrNull;
    if (matchedProduct != null && matchedProduct.stock > 0) {
      ref.read(cartProvider.notifier).addProduct(matchedProduct);
      _searchController.clear();
      setState(() {
        _searchQuery = '';
      });
      _focusNode.requestFocus();
    }
  }


  void _showCheckoutModal(BuildContext context, List<dynamic> cartItems, double subtotal) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
                                '${item.product.name} x${item.quantity}',
                                style: const TextStyle(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 32),
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
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context); // Close modal
                          await ref.read(salesProvider.notifier).completeSale();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Sale Completed Successfully!'),
                              backgroundColor: Colors.green,
                            ));
                          }
                        },
                        child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productProvider);
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    return Row(
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
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Dish Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SingleChildScrollView(
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
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '8',
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.grey.shade600,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh, size: 16),
                            SizedBox(width: 4),
                            Text('Refresh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
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
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: productsState.when(
                      data: (products) {
                        var filtered = products.where((p) {
                          final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
                          final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                                (p.barcode != null && p.barcode!.contains(_searchQuery));
                          return matchesCategory && matchesSearch;
                        }).toList();

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

                            return Card(
                              elevation: 0,
                              shadowColor: Colors.black.withValues(alpha: 0.05),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              clipBehavior: Clip.antiAlias,
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
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      product.name,
                                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹${product.price.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              InkWell(
                                                onTap: (!isOutOfStock) ? () {
                                                  ref.read(cartProvider.notifier).addProduct(product);
                                                  _focusNode.requestFocus();
                                                } : null,
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: isOutOfStock ? Colors.grey.shade300 : (inCart ? Colors.white : const Color(0xFF1E293B)),
                                                    border: inCart ? Border.all(color: Colors.grey.shade300) : null,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      isOutOfStock ? 'Not Available' : (inCart ? 'Add More ( ${cartItem.quantity} )' : '+ Add to Cart'),
                                                      style: TextStyle(
                                                        color: isOutOfStock ? Colors.white : (inCart ? Colors.black87 : Colors.white),
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ),
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
                                ],
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
          width: 320,
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
                                            item.product.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text('(${item.quantity})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('₹${item.product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Row(
                                          children: [
                                            const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => ref.read(cartProvider.notifier).removeProduct(item.product),
                                              child: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
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
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: cartItems.isEmpty ? null : () {
                          _showCheckoutModal(context, cartItems, subtotal);
                        },
                        child: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
