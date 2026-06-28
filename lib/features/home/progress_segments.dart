import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/coupon.dart';
import 'status_badge.dart';

class ProgressSegments extends StatelessWidget {
  final List<CouponStatus> statuses;

  const ProgressSegments({
    super.key,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount =
        statuses.where((status) => status != CouponStatus.pending).length;

    return Column(
      children: [
        Row(
          children: statuses
              .map(
                (status) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: status == CouponStatus.pending
                          ? AppColors.border
                          : statusColor(status).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Text(
              '$completedCount / ${statuses.length}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'tamamlandı',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}