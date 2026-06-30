import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool live;

  const SectionHeader({
    super.key,
    required this.title,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (live)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}