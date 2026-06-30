import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    fontFamily: 'Arial',
    colorScheme: const ColorScheme.light(
      primary: AppColors.brandLight,
      surface: AppColors.cardLight,
      error: AppColors.redLight,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    fontFamily: 'Arial',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.brandDark,
      surface: AppColors.cardDark,
      error: AppColors.redDark,
    ),
  );
}
