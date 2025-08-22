import 'package:flutter/material.dart';

class AppColors {
  // Primary Green Theme Colors (matching estimates design)
  static const Color primaryGreen = Color(0xFF1B4D3E);
  static const Color mediumGreen = Color(0xFF2D6A4F);
  static const Color lightGreen = Color(0xFF40916C);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFE0E0E0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryGreen, mediumGreen, lightGreen],
  );
}
