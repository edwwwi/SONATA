import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/sale.dart';
import 'package:ice_cream_pos/models/sale_item.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';
import 'package:ice_cream_pos/providers/cart_provider.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/stock_provider.dart';
import 'package:uuid/uuid.dart';
////SALES
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

    int? finalSaleId;

    await db.transaction((txn) async {
      // Insert sale
      final saleId = await txn.insert('sales', sale.toMap());
      finalSaleId = saleId;

      // Insert sale items and update stock
      for (var item in cartItems) {
        final saleItem = SaleItem(
          saleId: saleId,
          productId: item.product.id!,
          quantity: item.quantity,
          price: item.product.price,
        );
        await txn.insert('sale_items', saleItem.toMap());
        
        // Fetch current stock and update inside transaction
        final productMaps = await txn.query('products', where: 'id = ?', whereArgs: [item.product.id!]);
        if (productMaps.isNotEmpty) {
          final currentStock = productMaps.first['stock'] as int;
          final productName = productMaps.first['name'] as String;
          final newStock = currentStock - item.quantity;
          
          await txn.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [item.product.id!]);
          
          // Record stock movement OUT inside transaction
          await ref.read(stockProvider.notifier).recordSaleMovement(
            txn, 
            item.product.id!, 
            item.quantity, 
            productName, 
            currentStock, 
            newStock
          );
        }
      }
    });

    if (finalSaleId != null) {
      // Invalidate products to refresh the stock amounts in UI
      ref.invalidate(productProvider);
      
      // Clear cart
      ref.read(cartProvider.notifier).clearCart();
      
      // Update local sales state
      state = AsyncValue.data([sale.copyWith(id: finalSaleId), ...state.value ?? []]);
    }
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
