import 'package:flutter/material.dart';

class AppColors {
  // Vibrant Boutique Palette
  static const premiumPink = Color(0xFFFDE7F0);
  static const deepMaroon = Color(0xFF4A0E26);
  static const accentRose = Color(0xFFE91E63);
  static const premiumGold = Color(0xFFB76E79);
  
  // Slate Scale
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);

  // Background Colors (Restored for compatibility)
  static const pageStart = Color(0xFFFFF5F9);
  static const pageMiddle = Color(0xFFFDF2F8);
  static const pageEnd = Color(0xFFFCE7F3);

  // Background Gradients
  static const pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pageStart, pageMiddle, pageEnd],
  );

  static const sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5D162F), Color(0xFF3B081B)],
  );

  static const premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB76E79), Color(0xFFD4A5A5)],
  );

  static LinearGradient glassGradient({Color tint = Colors.white}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tint.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.1),
        ],
      );
}
