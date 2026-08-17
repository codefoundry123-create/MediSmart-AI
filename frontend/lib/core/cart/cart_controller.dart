import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/medicine_model.dart';

class CartController extends ChangeNotifier {
  final List<CartItemModel> _cartItems = [];

  List<CartItemModel> get cartItems => _cartItems;

  int get totalItems =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(MedicineModel medicine, int quantity) {
    int index =
        _cartItems.indexWhere((item) => item.medicine.name == medicine.name);

    if (index != -1) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(
        CartItemModel(medicine: medicine, quantity: quantity),
      );
    }

    notifyListeners();
  }

  void increaseQuantity(int index) {
    _cartItems[index].quantity++;
    notifyListeners();
  }

  void decreaseQuantity(int index) {
    if (_cartItems[index].quantity > 1) {
      _cartItems[index].quantity--;
    } else {
      _cartItems.removeAt(index);
    }
    notifyListeners();
  }

 void removeItem(int index) {
  _cartItems.removeAt(index);
  notifyListeners();
}

void clearCart() {
  _cartItems.clear();
  notifyListeners();
}

double getTotalPrice() {
    double total = 0;
    for (var item in _cartItems) {
      total += double.parse(item.medicine.price) * item.quantity;
    }
    return total;
  }
}
