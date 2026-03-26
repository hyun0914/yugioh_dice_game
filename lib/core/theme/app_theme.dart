import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.p1,
        surface: AppColors.panel,
        onPrimary: AppColors.dark,
        onSecondary: Colors.white,
        onSurface: AppColors.text,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.text, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.muted, fontSize: 11),
        titleLarge: TextStyle(
          color: AppColors.goldLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
        titleMedium: TextStyle(
          color: AppColors.gold,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.gold,
          fontSize: 14,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.muted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.panel,
          foregroundColor: AppColors.goldLight,
          side: const BorderSide(color: AppColors.gold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(letterSpacing: 1.5, fontSize: 12),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.border),
        ),
        elevation: 0,
      ),
      dividerColor: AppColors.border,
    );
  }
}
