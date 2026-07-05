import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  final bool isBoxSale;

  CartItem({required this.product, this.quantity = 1, this.isBoxSale = false});

  double get totalPrice => (isBoxSale ? product.boxPrice : product.price) * quantity;
  
  String get displayName => isBoxSale ? '${product.name} (Unit)' : product.name;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void addProduct(Product product, {bool isBoxSale = false}) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id && item.isBoxSale == isBoxSale);
    if (existingIndex < 0) {
      // Only add if not already in cart
      state = [...state, CartItem(product: product, isBoxSale: isBoxSale)];
    }
  }

  void increaseQuantity(Product product, {bool isBoxSale = false}) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id && item.isBoxSale == isBoxSale);
    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state);
      updatedList[existingIndex].quantity += 1;
      state = updatedList;
    }
  }

  void decreaseQuantity(Product product, {bool isBoxSale = false}) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id && item.isBoxSale == isBoxSale);
    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state);
      if (updatedList[existingIndex].quantity > 1) {
        updatedList[existingIndex].quantity -= 1;
        state = updatedList;
      } else {
        removeProduct(product, isBoxSale: isBoxSale);
      }
    }
  }

  void removeProduct(Product product, {bool isBoxSale = false}) {
    state = state.where((item) => !(item.product.id == product.id && item.isBoxSale == isBoxSale)).toList();
  }

  void clearCart() {
    state = [];
  }

  double get subtotal {
    return state.fold(0, (total, item) => total + item.totalPrice);
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});
