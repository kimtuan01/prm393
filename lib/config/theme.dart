import 'package:flutter/material.dart';

class AppTheme {
  // Colors từ Money Flow design
  static const Color primaryTeal = Color(0xFF4ECDC4);
  static const Color primaryNavy = Color(0xFF2C3E50);
  static const Color accentGreen = Color(0xFF27AE60);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color lightGray = Color(0xFFF5F6F7);

  // Text Styles
  static const TextStyle logoText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle sloganText = TextStyle(
    fontSize: 16,
    color: textSecondary,
    fontStyle: FontStyle.italic,
  );

  static ThemeData lightTheme = ThemeData(
    primarySwatch: MaterialColor(0xFF4ECDC4, {
      50: Color(0xFFE0F7F5),
      100: Color(0xFFB3ECEB),
      200: Color(0xFF80DFE0),
      300: Color(0xFF4DD2D4),
      400: Color(0xFF26C8CB),
      500: Color(0xFF4ECDC4),
      600: Color(0xFF00B7BB),
      700: Color(0xFF00A5AA),
      800: Color(0xFF009499),
      900: Color(0xFF007580),
    }),
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
  );
}
