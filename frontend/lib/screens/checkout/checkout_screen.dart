import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/cart/cart_controller.dart';
import '../../core/orders/order_service.dart';
import '../../core/theme/app_colors.dart';
import '../orders/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();

  bool isLoading = false;
  String selectedPayment = "Cash on Delivery";
  String address = "House 123, Main Street, Lahore";

  void _placeOrder() async {
    final cart = context.read<CartController>();

    setState(() => isLoading = true);

    final String? error = await _orderService.placeOrder(
      cart: cart,
      address: address,
      paymentMethod: selectedPayment,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (error == null) {
      cart.clearCart();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    final subtotal = cart.getTotalPrice();
    final tax = subtotal * 0.05;
    const deliveryFee = 100.0;
    final total = subtotal + tax + deliveryFee;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 92),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, "Delivery Address"),

                  const SizedBox(height: 10),

                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        "Mueeza Ahmad",
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        address,
                        style: TextStyle(color: subtitleColor),
                      ),
                      trailing: const Text(
                        "Change",
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  _sectionTitle(context, "Order Summary"),

                  const SizedBox(height: 10),

                  ...cart.cartItems.map(
                    (item) => Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: Image.asset(
                          item.medicine.image,
                          width: 50,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.medication, color: subtitleColor),
                        ),
                        title: Text(
                          item.medicine.name,
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          "${item.quantity} x Rs ${item.medicine.price}",
                          style: TextStyle(color: subtitleColor),
                        ),
                        trailing: Text(
                          "Rs ${(double.parse(item.medicine.price) * item.quantity).toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  _sectionTitle(context, "Payment Method"),

                  const SizedBox(height: 10),

                  _paymentCard(
                    context: context,
                    value: "Cash on Delivery",
                    icon: Icons.money,
                  ),

                  _paymentCard(
                    context: context,
                    value: "Card Payment",
                    icon: Icons.credit_card,
                  ),

                  const SizedBox(height: 25),

                  _buildPriceRow(context, "Subtotal", subtotal),
                  _buildPriceRow(context, "Tax (5%)", tax),
                  _buildPriceRow(context, "Delivery Fee", deliveryFee),
                  Divider(color: isDark ? Colors.white24 : Colors.black12),
                  _buildPriceRow(context, "Total", total, isTotal: true),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: isDark
                        ? Colors.black.withOpacity(0.45)
                        : Colors.black12,
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: isLoading ? null : _placeOrder,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Place Order • Rs ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _paymentCard({
    required BuildContext context,
    required String value,
    required IconData icon,
  }) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: RadioListTile<String>(
        activeColor: AppColors.primary,
        value: value,
        groupValue: selectedPayment,
        onChanged: (newValue) {
          if (newValue == null) return;
          setState(() => selectedPayment = newValue);
        },
        title: Text(value, style: TextStyle(color: textColor)),
        secondary: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String title,
    double amount, {
    bool isTotal = false,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "Rs ${amount.toStringAsFixed(0)}",
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
