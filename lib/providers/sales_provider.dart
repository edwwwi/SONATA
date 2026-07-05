import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/sale.dart';
import 'package:ice_cream_pos/models/sale_item.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';
import 'package:ice_cream_pos/providers/cart_provider.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/stock_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:ice_cream_pos/core/logger.dart';

////SALES
class SalesNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    return _fetchSales();
  }

  Future<List<Sale>> _fetchSales() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final maps = await db.query('sales', orderBy: 'created_at DESC');
      return maps.map((e) => Sale.fromMap(e)).toList();
    } catch (e, st) {
      await AppLogger.log('SalesProvider', 'Failed to fetch sales', exception: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> completeSale({bool isDue = false, String? dueName}) async {
    try {
      final cartItems = ref.read(cartProvider);
      if (cartItems.isEmpty) throw Exception('Cart is empty');

      final db = await ref.read(databaseProvider.future);
      final subtotal = ref.read(cartProvider.notifier).subtotal;
      
      final billNumber = const Uuid().v4().substring(0, 8).toUpperCase();
      
      final sale = Sale(
        billNumber: billNumber,
        totalAmount: subtotal,
        isDue: isDue,
        dueName: dueName,
        createdAt: DateTime.now(),
      );

      int? finalSaleId;

      await db.transaction((txn) async {
        // Insert sale
        final saleId = await txn.insert('sales', sale.toMap());
        finalSaleId = saleId;

        // Insert sale items and update stock
        for (var item in cartItems) {
          if (item.quantity <= 0) throw Exception('Invalid quantity for ${item.product.name}');
          
          final saleItem = SaleItem(
            saleId: saleId,
            productId: item.product.id!,
            quantity: item.quantity,
            price: item.isBoxSale ? item.product.boxPrice : item.product.price,
          );
          await txn.insert('sale_items', saleItem.toMap());
          
          // Fetch current stock and update inside transaction
          final productMaps = await txn.query('products', where: 'id = ?', whereArgs: [item.product.id!]);
          if (productMaps.isNotEmpty) {
            final currentStock = productMaps.first['stock'] as int;
            final productName = item.isBoxSale ? '${productMaps.first['name']} (Unit)' : productMaps.first['name'] as String;
            final stockReduction = item.isBoxSale ? (item.quantity * item.product.piecesPerBox) : item.quantity;
            final newStock = currentStock - stockReduction;
            
            if (newStock < 0) {
              throw Exception('Insufficient Stock for $productName. Cannot go below zero.');
            }
            
            await txn.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [item.product.id!]);
            
            // Record stock movement OUT inside transaction
            await ref.read(stockProvider.notifier).recordSaleMovement(
              txn, 
              item.product.id!, 
              stockReduction, 
              productName, 
              currentStock, 
              newStock
            );
          } else {
            throw Exception('Product not found in database: ${item.product.name}');
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
    } catch (e, st) {
      await AppLogger.log('SalesProvider', 'Transaction failed and rolled back', exception: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> markBillAsPaid(int saleId) async {
    try {
      final db = await ref.read(databaseProvider.future);
      await db.update('sales', {'is_due': 0}, where: 'id = ?', whereArgs: [saleId]);
      ref.invalidateSelf();
    } catch (e, st) {
      await AppLogger.log('SalesProvider', 'Failed to mark bill as paid', exception: e, stackTrace: st);
      rethrow;
    }
  }
  
  Future<List<SaleItem>> getSaleItems(int saleId) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final maps = await db.query('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      return maps.map((e) => SaleItem.fromMap(e)).toList();
    } catch (e, st) {
      await AppLogger.log('SalesProvider', 'Failed to get sale items', exception: e, stackTrace: st);
      rethrow;
    }
  }
}

final salesProvider = AsyncNotifierProvider<SalesNotifier, List<Sale>>(() {
  return SalesNotifier();
});
