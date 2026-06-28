import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Arial',
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      surface: AppColors.card,
      error: AppColors.red,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Arial',
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      surface: AppColors.card,
      error: AppColors.red,
    ),
  );
}
