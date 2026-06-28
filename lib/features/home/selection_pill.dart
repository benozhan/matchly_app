import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// Neutral-white selection chip — no brand blue.
class SelectionPill extends StatelessWidget {
  final String text;
  final bool dimmed;

  const SelectionPill({
    super.key,
    required this.text,
    required this.dimmed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dimmed ? AppColors.textSecondary : AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
