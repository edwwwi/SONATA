import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/sale.dart';
import 'package:ice_cream_pos/models/sale_item.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';
import 'package:ice_cream_pos/providers/cart_provider.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:ice_cream_pos/providers/stock_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
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
      
      final todayStr = DateFormat('ddMMyy').format(DateTime.now());
      final prefix = 'B$todayStr-';

      int? finalSaleId;
      String? finalBillNumber;

      await db.transaction((txn) async {
        // Generate sequential bill number
        final result = await txn.rawQuery("SELECT bill_number FROM sales WHERE bill_number LIKE '$prefix%' ORDER BY id DESC LIMIT 1");
        int nextSeq = 1;
        if (result.isNotEmpty) {
           final lastBill = result.first['bill_number'] as String;
           final seqPart = lastBill.split('-').last;
           nextSeq = (int.tryParse(seqPart) ?? 0) + 1;
        }
        final billNumber = '$prefix$nextSeq';
        finalBillNumber = billNumber;

        final sale = Sale(
          billNumber: billNumber,
          totalAmount: subtotal,
          isDue: isDue,
          dueName: dueName,
          createdAt: DateTime.now(),
        );

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
            final productMap = productMaps.first;
            if (productMap['is_active'] == 0) {
              throw Exception('Product ${item.product.name} is not active.');
            }
            final currentStock = productMap['stock'] as int;
            final price = item.isBoxSale ? (productMap['box_price'] as num).toDouble() : (productMap['price'] as num).toDouble();
            
            if (price <= 0) {
              throw Exception('Invalid price for ${item.product.name}. Price must be greater than zero.');
            }
            
            final productName = item.isBoxSale ? '${productMap['name']} (Unit)' : productMap['name'] as String;
            final stockReduction = item.isBoxSale ? (item.quantity * (productMap['pieces_per_box'] as int)) : item.quantity;
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

      if (finalSaleId != null && finalBillNumber != null) {
        // Invalidate products to refresh the stock amounts in UI
        ref.invalidate(productProvider);
        ref.invalidate(nextBillNumberProvider);
        
        // Clear cart
        ref.read(cartProvider.notifier).clearCart();
        
        final sale = Sale(
          id: finalSaleId,
          billNumber: finalBillNumber!,
          totalAmount: subtotal,
          isDue: isDue,
          dueName: dueName,
          createdAt: DateTime.now(),
        );
        // Update local sales state
        state = AsyncValue.data([sale, ...state.value ?? []]);
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

final nextBillNumberProvider = FutureProvider.autoDispose<String>((ref) async {
  final db = await ref.read(databaseProvider.future);
  final todayStr = DateFormat('ddMMyy').format(DateTime.now());
  final prefix = 'B$todayStr-';
  final result = await db.rawQuery("SELECT bill_number FROM sales WHERE bill_number LIKE '$prefix%' ORDER BY id DESC LIMIT 1");
  int nextSeq = 1;
  if (result.isNotEmpty) {
     final lastBill = result.first['bill_number'] as String;
     final seqPart = lastBill.split('-').last;
     nextSeq = (int.tryParse(seqPart) ?? 0) + 1;
  }
  return '$prefix$nextSeq';
});
