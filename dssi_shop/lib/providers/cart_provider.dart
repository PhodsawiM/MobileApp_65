import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  // getter สำหรับนับจำนวนชนิดของสินค้า (สำหรับแสดงว่ามีกี่รายการ)
  int get itemCount {
    return _items.length;
  }

  // getter สำหรับนับจำนวนสินค้าทั้งหมด (รวมทุกชิ้น)
  int get totalQuantity {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  }

  void addItem({required String productId, required String title, required double price}) {
    if (_items.containsKey(productId)) {
      _items.update(productId, (existing) => CartItem(
        id: existing.id,
        productId: existing.productId,
        title: existing.title,
        quantity: existing.quantity + 1,
        price: existing.price,
      ));
    } else {
      _items.putIfAbsent(productId, () => CartItem(
        id: DateTime.now().toIso8601String(),
        productId: productId,
        title: title,
        quantity: 1,
        price: price,
      ));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(productId, (existing) => CartItem(
        id: existing.id,
        productId: existing.productId,
        title: existing.title,
        quantity: existing.quantity - 1,
        price: existing.price,
      ));
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

