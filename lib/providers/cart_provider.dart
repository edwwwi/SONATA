import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ice_cream_pos/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void addProduct(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state);
      updatedList[existingIndex].quantity += 1;
      state = updatedList;
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void decreaseQuantity(Product product) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updatedList = List<CartItem>.from(state);
      if (updatedList[existingIndex].quantity > 1) {
        updatedList[existingIndex].quantity -= 1;
        state = updatedList;
      } else {
        removeProduct(product);
      }
    }
  }

  void removeProduct(Product product) {
    state = state.where((item) => item.product.id != product.id).toList();
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
