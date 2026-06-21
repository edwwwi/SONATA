import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';
import 'package:ice_cream_pos/providers/database_provider.dart';

class ProductNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final db = await ref.read(databaseProvider.future);
    final List<Map<String, dynamic>> maps = await db.query('products');
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<void> addProduct(Product product) async {
    final db = await ref.read(databaseProvider.future);
    final id = await db.insert('products', product.toMap());
    final newProduct = product.copyWith(id: id);
    state = AsyncValue.data([...state.value ?? [], newProduct]);
  }

  Future<void> updateProduct(Product product) async {
    final db = await ref.read(databaseProvider.future);
    await db.update('products', product.toMap(), where: 'id = ?', whereArgs: [product.id]);
    final updatedList = (state.value ?? []).map((p) => p.id == product.id ? product : p).toList();
    state = AsyncValue.data(updatedList);
  }

  Future<void> deleteProduct(int id) async {
    final db = await ref.read(databaseProvider.future);
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
    final updatedList = (state.value ?? []).where((p) => p.id != id).toList();
    state = AsyncValue.data(updatedList);
  }

  Future<void> reduceStock(int productId, int quantity) async {
    final db = await ref.read(databaseProvider.future);
    final productList = state.value ?? [];
    final index = productList.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final product = productList[index];
      final newStock = product.stock - quantity;
      
      await db.update('products', {'stock': newStock}, where: 'id = ?', whereArgs: [productId]);
      
      // Update state
      final updatedProduct = product.copyWith(stock: newStock);
      final updatedList = List<Product>.from(productList);
      updatedList[index] = updatedProduct;
      state = AsyncValue.data(updatedList);
    }
  }
}

final productProvider = AsyncNotifierProvider<ProductNotifier, List<Product>>(() {
  return ProductNotifier();
});
