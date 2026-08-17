import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/cart/profile_controller.dart';
import '../home/home_screen.dart';
import '../medicine/medicines_screen.dart';
import 'package:medismart_app/features/ai/screens/ai_screen.dart';
import '../carts/cart_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onCartTap: () => _onItemTapped(3)),
    const MedicinesScreen(),
    const AiScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Load user data when dashboard opens
    Future.microtask(() {
      context.read<ProfileController>().loadUserData();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "Medicines",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "AI Scan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Carts",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
