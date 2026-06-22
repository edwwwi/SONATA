import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productProvider);
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    return Row(
      children: [
        // Left Side: Products Section
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar: Search and Categories
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search product or scan barcode...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
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
                      const SizedBox(height: 16),
                      // Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(category, style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                )),
                                selected: isSelected,
                                selectedColor: Colors.blueAccent,
                                backgroundColor: Colors.white,
                                side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Products Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: productsState.when(
                      data: (products) {
                        // Filter products
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
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            final inCart = cartItems.any((item) => item.product.id == product.id);
                            final isOutOfStock = product.stock <= 0;

                            return Card(
                              elevation: 2,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: inCart ? Colors.blueAccent : Colors.transparent, width: 2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: (!isOutOfStock && !inCart) ? () {
                                  ref.read(cartProvider.notifier).addProduct(product);
                                  _focusNode.requestFocus();
                                } : null,
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: product.imagePath != null && File(product.imagePath!).existsSync()
                                              ? Image.file(File(product.imagePath!), fit: BoxFit.cover)
                                              : Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.icecream, size: 48, color: Colors.grey),
                                                ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.all(12.0),
                                            color: Colors.white,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const Spacer(),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      '₹${product.price.toStringAsFixed(2)}',
                                                      style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                                                    ),
                                                    Text(
                                                      'Stock: ${product.stock}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isOutOfStock ? Colors.red : Colors.grey[600],
                                                        fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isOutOfStock)
                                      Container(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        child: const Center(
                                          child: Text('OUT OF STOCK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                      ),
                                    if (inCart)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.blueAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, color: Colors.white, size: 16),
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
                ),
              ],
            ),
          ),
        ),
        
        // Right Side: Cart Sidebar
        Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              )
            ],
          ),
          child: Column(
            children: [
              // Cart Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: const Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.blueAccent),
                    SizedBox(width: 12),
                    Text('Current Bill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              
              // Cart Items
              Expanded(
                child: cartItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Cart is empty', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => ref.read(cartProvider.notifier).removeProduct(item.product),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('₹${item.product.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey[600])),
                                    Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Quantity Controls
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () => ref.read(cartProvider.notifier).decreaseQuantity(item.product),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.remove, size: 20),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        if (item.quantity < item.product.stock) {
                                          ref.read(cartProvider.notifier).increaseQuantity(item.product);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock')));
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.add, size: 20, color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              
              // Totals & Checkout
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: cartItems.isEmpty ? null : () {
                              ref.read(cartProvider.notifier).clearCart();
                            },
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: cartItems.isEmpty ? null : () async {
                              await ref.read(salesProvider.notifier).completeSale();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('Sale Completed Successfully!'),
                                  backgroundColor: Colors.green,
                                ));
                              }
                            },
                            child: const Text('Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      ],
    );
  }
}
