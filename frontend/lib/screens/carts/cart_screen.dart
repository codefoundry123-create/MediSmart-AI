import 'package:flutter/material.dart';
import 'package:medismart_app/screens/checkout/checkout_screen.dart';
import 'package:provider/provider.dart';
import '../../core/cart/cart_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = context.watch<CartController>();
    final cartItems = cartController.cartItems;

    return Scaffold(
      appBar: AppBar(title: const Text("My Cart")),
      body: cartItems.isEmpty
          ? const Center(
              child: Text("Your cart is empty", style: TextStyle(fontSize: 18)),
            )
          : Column(
              children: [
                /// Cart Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 5,
                              color: Colors.grey.shade200,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            /// Image
                            Image.asset(item.medicine.image, width: 60),

                            const SizedBox(width: 15),

                            /// Name + Quantity
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.medicine.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Rs ${item.medicine.price}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => cartController
                                            .decreaseQuantity(index),
                                        icon: const Icon(Icons.remove),
                                      ),
                                      Text(item.quantity.toString()),
                                      IconButton(
                                        onPressed: () => cartController
                                            .increaseQuantity(index),
                                        icon: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            /// Delete Button
                            IconButton(
                              onPressed: () => cartController.removeItem(index),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                /// TOTAL + CHECKOUT
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(blurRadius: 10, color: Colors.grey.shade300),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Rs ${cartController.getTotalPrice().toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff0F9D9A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Checkout",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    ); // <-- Scaffold closing parenthesis and semicolon
  }
}
