import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Arial',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.brand,
      surface: AppColors.card,
      error: AppColors.red,
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    fontFamily: 'Arial',
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      surface: Colors.white,
      error: AppColors.red,
    ),
  );
}
