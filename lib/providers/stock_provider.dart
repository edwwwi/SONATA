import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/stock_movement.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class StockNotifier extends AsyncNotifier<List<StockMovement>> {
  @override
  Future<List<StockMovement>> build() async {
    return _fetchMovements();
  }

  Future<List<StockMovement>> _fetchMovements() async {
    final db = await ref.read(databaseProvider.future);
    final List<Map<String, dynamic>> maps = await db.query('stock_movements', orderBy: 'created_at DESC');
    return maps.map((e) => StockMovement.fromMap(e)).toList();
  }

  Future<void> addStock(int productId, int quantity) async {
    final db = await ref.read(databaseProvider.future);
    StockMovement? newMovement;

    await db.transaction((txn) async {
      final productMaps = await txn.query('products', where: 'id = ?', whereArgs: [productId]);
      if (productMaps.isNotEmpty) {
        final currentStock = productMaps.first['stock'] as int;
        final productName = productMaps.first['name'] as String;
        final newStock = currentStock + quantity;
        
        // Update product stock in DB
        await txn.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [productId]);
        
        // Create movement record
        final movement = StockMovement(
          productId: productId,
          productName: productName,
          quantity: quantity,
          previousStock: currentStock,
          currentStock: newStock,
          movementType: quantity >= 0 ? 'STOCK_IN' : 'STOCK_OUT',
          remarks: quantity >= 0 ? 'Manual Stock Entry' : 'Manual Stock Reduction',
          createdAt: DateTime.now(),
        );
        
        final id = await txn.insert('stock_movements', movement.toMap());
        newMovement = movement.copyWith(id: id);
      }
    });
    
    if (newMovement != null) {
      // Refresh product provider and stock movements
      ref.invalidate(productProvider);
      state = AsyncValue.data([newMovement!, ...state.value ?? []]);
    }
  }

  Future<void> recordSaleMovement(Transaction txn, int productId, int quantity, String productName, int previousStock, int currentStock) async {
    final movement = StockMovement(
      productId: productId,
      productName: productName,
      quantity: -quantity, // Store as negative for sale
      previousStock: previousStock,
      currentStock: currentStock,
      movementType: 'SALE',
      remarks: 'Sold in Bill',
      createdAt: DateTime.now(),
    );
    await txn.insert('stock_movements', movement.toMap());
    
    // Invalidate state to fetch new movements after the transaction completes
    ref.invalidateSelf();
  }
}

final stockProvider = AsyncNotifierProvider<StockNotifier, List<StockMovement>>(() {
  return StockNotifier();
});
