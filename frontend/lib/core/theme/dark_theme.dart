import 'package:flutter/material.dart';
import 'app_colors.dart';

class DarkTheme {
  static ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamily: 'Poppins',

    cardColor: AppColors.darkCard,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      foregroundColor: Colors.white,
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkText),
      bodyMedium: TextStyle(color: Colors.white70),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
    ),
  );
}
