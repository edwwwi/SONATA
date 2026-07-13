import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/screens/bulk_stock_screen.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}
class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Product Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
            child: Row(
              children: [
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
                              child: Text(category, style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13
                              )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 250,
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search Products',
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: productsState.when(
        data: (products) {
          var filtered = products.where((p) {
            final matchesCategory = _selectedCategory == 'All' || 
                                    p.company == _selectedCategory || 
                                    p.type == _selectedCategory;
            final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                  (p.barcode != null && p.barcode!.contains(_searchQuery)) ||
                                  p.company.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesCategory && matchesSearch;
          }).toList();

          // Sort by stock ascending (lowest stock first)
          filtered.sort((a, b) => a.stock.compareTo(b.stock));

          if (filtered.isEmpty) {
            return const Center(child: Text('No products found.', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final product = filtered[index];
              final isOutOfStock = product.stock <= 0;
              final isLowStock = product.stock > 0 && product.stock < product.minimumStock;
              
              final mockDate = DateTime.now().subtract(Duration(days: index * 2 + 1));
              final formattedDate = '${mockDate.day}/${mockDate.month}/${mockDate.year}';

              return Container(
                decoration: BoxDecoration(
                  color: isLowStock ? Colors.orange.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: product.color != null 
                        ? Color(product.color!) 
                        : (isLowStock ? Colors.orange.shade200 : Colors.grey.shade200),
                    width: product.color != null ? 3.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Prominent Stock Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade100 : (isLowStock ? Colors.orange.shade100 : Colors.green.shade50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isOutOfStock ? Colors.grey.shade300 : (isLowStock ? Colors.orange.shade300 : Colors.green.shade200)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (product.isBoxPiece) ...[
                              Text(
                                '${product.stock ~/ product.piecesPerBox} Unit',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock ? Colors.grey.shade700 : Colors.green.shade800,
                                ),
                              ),
                              Text(
                                '${product.stock % product.piecesPerBox} Nos',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock ? Colors.grey.shade600 : Colors.green.shade600,
                                ),
                              ),
                            ] else ...[
                              Text(
                                '${product.stock}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock ? Colors.grey.shade700 : (isLowStock ? Colors.orange.shade800 : Colors.green.shade800),
                                ),
                              ),
                              Text(
                                isLowStock ? 'LOW STOCK' : 'IN STOCK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOutOfStock ? Colors.grey.shade600 : (isLowStock ? Colors.orange.shade800 : Colors.green.shade600),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${product.company} ${product.name}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.type,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.update, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Added: $formattedDate',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                ),
                              ],
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
}
