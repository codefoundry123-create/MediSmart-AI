import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/cart/cart_controller.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> placeOrder({
    required CartController cart,
    required String address,
    required String paymentMethod,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "User not logged in";

      final subtotal = cart.getTotalPrice();
      final tax = subtotal * 0.05;
      const deliveryFee = 100.0;
      final total = subtotal + tax + deliveryFee;

      // Build items list
      final items = cart.cartItems
          .map(
            (item) => {
              'name': item.medicine.name,
              'price': item.medicine.price,
              'quantity': item.quantity,
              'image': item.medicine.image,
            },
          )
          .toList();

      // Save order to Firestore
      await _firestore.collection('orders').add({
        'userId': user.uid,
        'items': items,
        'subtotal': subtotal,
        'tax': tax,
        'deliveryFee': deliveryFee,
        'total': total,
        'address': address,
        'paymentMethod': paymentMethod,
        'status': 'Pending',
        'createdAt': DateTime.now(),
      });

      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // Get orders for current user
  Stream<QuerySnapshot> getMyOrders() {
    final user = _auth.currentUser;
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user!.uid)
        .snapshots();
  }
}
