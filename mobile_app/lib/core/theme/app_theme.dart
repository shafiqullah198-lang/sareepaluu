import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'spacing.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.premiumGold),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pageStart,
      textTheme: AppTypography.textTheme,
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(AppSpacing.cardRadius))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.compactRadius),
          borderSide:
              BorderSide(color: AppColors.premiumPink.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.compactRadius),
          borderSide:
              BorderSide(color: AppColors.premiumPink.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.compactRadius),
          borderSide: BorderSide(
              color: AppColors.premiumGold.withValues(alpha: 0.85), width: 1.5),
        ),
      ),
    );
  }
}
