import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/stock_movement.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';
import 'package:ice_cream_pos/providers/product_provider.dart';

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
    
    // Create movement record
    final movement = StockMovement(
      productId: productId,
      quantity: quantity,
      movementType: 'IN',
      createdAt: DateTime.now(),
    );
    final id = await db.insert('stock_movements', movement.toMap());
    
    // Update product stock in DB
    final productMaps = await db.query('products', where: 'id = ?', whereArgs: [productId]);
    if (productMaps.isNotEmpty) {
      final currentStock = productMaps.first['stock'] as int;
      await db.update('products', {'stock': currentStock + quantity}, where: 'id = ?', whereArgs: [productId]);
    }
    
    // Refresh product provider and stock movements
    ref.invalidate(productProvider);
    state = AsyncValue.data([movement.copyWith(id: id), ...state.value ?? []]);
  }

  Future<void> recordSaleMovement(int productId, int quantity) async {
    final db = await ref.read(databaseProvider.future);
    final movement = StockMovement(
      productId: productId,
      quantity: quantity,
      movementType: 'OUT',
      createdAt: DateTime.now(),
    );
    await db.insert('stock_movements', movement.toMap());
    // Invalidate state to fetch new movements
    ref.invalidateSelf();
  }
}

final stockProvider = AsyncNotifierProvider<StockNotifier, List<StockMovement>>(() {
  return StockNotifier();
});
