import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/sale.dart';
import 'package:ice_cream_pos/models/sale_item.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';
import 'package:ice_cream_pos/providers/cart_provider.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/stock_provider.dart';
import 'package:uuid/uuid.dart';

class SalesNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    return _fetchSales();
  }

  Future<List<Sale>> _fetchSales() async {
    final db = await ref.read(databaseProvider.future);
    final maps = await db.query('sales', orderBy: 'created_at DESC');
    return maps.map((e) => Sale.fromMap(e)).toList();
  }

  Future<void> completeSale() async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    final db = await ref.read(databaseProvider.future);
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    
    final billNumber = const Uuid().v4().substring(0, 8).toUpperCase();
    
    final sale = Sale(
      billNumber: billNumber,
      totalAmount: subtotal,
      createdAt: DateTime.now(),
    );

    // Insert sale
    final saleId = await db.insert('sales', sale.toMap());

    // Insert sale items and update stock
    for (var item in cartItems) {
      final saleItem = SaleItem(
        saleId: saleId,
        productId: item.product.id!,
        quantity: item.quantity,
        price: item.product.price,
      );
      await db.insert('sale_items', saleItem.toMap());
      
      // Reduce product stock in state and db
      await ref.read(productProvider.notifier).reduceStock(item.product.id!, item.quantity);
      
      // Record stock movement OUT
      await ref.read(stockProvider.notifier).recordSaleMovement(item.product.id!, item.quantity);
    }

    // Clear cart
    ref.read(cartProvider.notifier).clearCart();
    
    // Update local sales state
    state = AsyncValue.data([sale.copyWith(id: saleId), ...state.value ?? []]);
  }
  
  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final db = await ref.read(databaseProvider.future);
    final maps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
    return maps.map((e) => SaleItem.fromMap(e)).toList();
  }
}

final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(() {
  return SalesNotifier();
});
