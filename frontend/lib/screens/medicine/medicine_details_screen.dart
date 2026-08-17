import 'package:flutter/material.dart';
import 'package:medismart_app/screens/carts/cart_screen.dart';
import 'package:provider/provider.dart';

import '../../../core/cart/cart_controller.dart';
import '../../../core/models/medicine_model.dart';
import '../../../core/theme/app_colors.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;

  const MedicineDetailsScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  int quantity = 1;
  bool isFavorite = false;

  String _value(String key) {
    return widget.medicine[key]?.toString() ?? "";
  }

  void _addToCart() {
    final cart = context.read<CartController>();

    cart.addToCart(
      MedicineModel(
        name: _value("name"),
        salt: _value("salt"),
        price: _value("price"),
        image: _value("image"),
        category: _value("category"),
      ),
      quantity,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Added to Cart")));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50),
            height: 300,
            child: Stack(
              children: [
                Positioned(
                  left: 16,
                  top: 10,
                  child: CircleAvatar(
                    backgroundColor: cardColor,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.primary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Positioned(
                  right: 20,
                  top: 10,
                  child: Consumer<CartController>(
                    builder: (context, cart, child) => Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: cardColor,
                          child: IconButton(
                            icon: const Icon(Icons.shopping_cart),
                            color: AppColors.primary,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        if (cart.totalItems > 0)
                          Positioned(
                            right: 0,
                            child: CircleAvatar(
                              radius: 8,
                              backgroundColor: Colors.red,
                              child: Text(
                                cart.totalItems.toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Center(
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        _value("image"),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.medication,
                          size: 70,
                          color: subtitleColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _value("name"),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: cardColor,
                          child: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      _value("salt"),
                      style: TextStyle(color: subtitleColor, fontSize: 15),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.teal, size: 18),
                        const Icon(Icons.star, color: Colors.teal, size: 18),
                        const Icon(Icons.star, color: Colors.teal, size: 18),
                        const Icon(Icons.star, color: Colors.teal, size: 18),
                        const Icon(
                          Icons.star_half,
                          color: Colors.teal,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text("4.0", style: TextStyle(color: textColor)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  if (quantity > 1) {
                                    setState(() => quantity--);
                                  }
                                },
                                icon: Icon(Icons.remove, color: textColor),
                              ),
                              Text(
                                quantity.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() => quantity++);
                                },
                                icon: Icon(Icons.add, color: textColor),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          "Rs ${_value("price")}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Text(
                      "Description",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "This medicine helps relieve pain, fever and inflammation. Always consult your doctor before use.",
                      style: TextStyle(color: subtitleColor),
                    ),

                    const SizedBox(height: 40),

                    Row(
                      children: [
                        Container(
                          height: 55,
                          width: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.shopping_cart),
                            color: AppColors.primary,
                            onPressed: _addToCart,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: _addToCart,
                              child: const Text(
                                "Buy Now",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
