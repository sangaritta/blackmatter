import 'package:flutter/foundation.dart';
import 'package:portal/Screens/Home/Marketplace/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => _items;

  double get totalPrice =>
      _items.fold(0, (total, product) => total + product.price);

  void addToCart(Product product) {
    // Check if product already exists in cart
    if (!_items.any((item) => item.id == product.id)) {
      _items.add(product);
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
