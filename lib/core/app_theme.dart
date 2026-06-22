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
}