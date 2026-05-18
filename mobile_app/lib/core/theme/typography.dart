import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  static TextTheme get textTheme {
    final baseTheme = GoogleFonts.outfitTextTheme();
    final playfairTheme = GoogleFonts.playfairDisplayTextTheme();
    
    return baseTheme.copyWith(
      displayLarge: playfairTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slate900),
      headlineLarge: playfairTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slate900, letterSpacing: -1.0),
      headlineMedium: playfairTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slate800, letterSpacing: -0.5),
      headlineSmall: playfairTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slate800),
      
      titleLarge: playfairTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.slate800),
      titleMedium: baseTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.slate800),
      titleSmall: baseTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.slate700),
      
      bodyLarge: baseTheme.bodyLarge?.copyWith(color: AppColors.slate700, fontSize: 16),
      bodyMedium: baseTheme.bodyMedium?.copyWith(color: AppColors.slate600, fontSize: 14),
      bodySmall: baseTheme.bodySmall?.copyWith(color: AppColors.slate500, fontSize: 12),
      
      labelLarge: baseTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1),
      labelMedium: baseTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1),
      labelSmall: baseTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.slate400, letterSpacing: 1.2),
    );
  }
}
