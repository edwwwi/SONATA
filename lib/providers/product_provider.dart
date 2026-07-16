import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';
import 'package:ice_cream_pos/core/logger.dart';

class ProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    try {
      final db = await ref.read(databaseProvider.future);
      final List<Map<String, dynamic>> maps = await db.query('products', where: 'is_active = 1');
      return maps.map((e) => Product.fromMap(e)).toList();
    } catch (e, st) {
      await AppLogger.log('ProductProvider', 'Failed to fetch products', exception: e, stackTrace: st);
      rethrow;
    }
  }

  void _validateProduct(Product product) {
    if (product.name.trim().isEmpty) throw Exception('Product name cannot be empty');
    if (product.price <= 0) throw Exception('Price must be greater than 0');
    if (product.stock < 0) throw Exception('Stock cannot be negative');
  }

  Future<void> _validateBarcodeUniqueness(String? barcode, int? excludeId) async {
    if (barcode == null || barcode.trim().isEmpty) return;
    
    final db = await ref.read(databaseProvider.future);
    List<Map<String, dynamic>> result;
    if (excludeId != null) {
      result = await db.query('products', where: '(barcode = ? OR box_barcode = ?) AND id != ? AND is_active = 1', whereArgs: [barcode, barcode, excludeId]);
    } else {
      result = await db.query('products', where: '(barcode = ? OR box_barcode = ?) AND is_active = 1', whereArgs: [barcode, barcode]);
    }
    
    if (result.isNotEmpty) {
      throw Exception('Barcode already exists.');
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      _validateProduct(product);
      await _validateBarcodeUniqueness(product.barcode, null);
      if (product.isBoxPiece) await _validateBarcodeUniqueness(product.boxBarcode, null);

      final db = await ref.read(databaseProvider.future);
      int? id;
      await db.transaction((txn) async {
        id = await txn.insert('products', product.toMap());
      });
      if (id != null) {
        final newProduct = product.copyWith(id: id, isActive: true);
        state = AsyncValue.data([...state.value ?? [], newProduct]);
      }
    } catch (e, st) {
      await AppLogger.log('ProductProvider', 'Failed to add product', exception: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      _validateProduct(product);
      await _validateBarcodeUniqueness(product.barcode, product.id);
      if (product.isBoxPiece) await _validateBarcodeUniqueness(product.boxBarcode, product.id);

      final db = await ref.read(databaseProvider.future);
      await db.transaction((txn) async {
        await txn.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
      });
      final updatedList = (state.value ?? []).map((p) => p.id == product.id ? product : p).toList();
      state = AsyncValue.data(updatedList);
    } catch (e, st) {
      await AppLogger.log('ProductProvider', 'Failed to update product', exception: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final db = await ref.read(databaseProvider.future);
      // Soft Delete
      await db.transaction((txn) async {
        await txn.update('products', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
      });
      final updatedList = (state.value ?? []).where((p) => p.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e, st) {
      await AppLogger.log('ProductProvider', 'Failed to soft-delete product', exception: e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> reduceStock(int productId, int quantity) async {
    try {
      final db = await ref.read(databaseProvider.future);
      final productList = state.value ?? [];
      final index = productList.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final product = productList[index];
        final newStock = product.stock - quantity;
        
        if (newStock < 0) {
          throw Exception('Insufficient Stock');
        }
        
        await db.transaction((txn) async {
          await txn.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [productId]);
        });
        
        // Update state
        final updatedProduct = product.copyWith(stock: newStock);
        final updatedList = List<Product>.from(productList);
        updatedList[index] = updatedProduct;
        state = AsyncValue.data(updatedList);
      }
    } catch (e, st) {
      await AppLogger.log('ProductProvider', 'Failed to reduce stock', exception: e, stackTrace: st);
      rethrow;
    }
  }
}

final productProvider = AsyncNotifierProvider<ProductNotifier, List<Product>>(() {
  return ProductNotifier();
});
