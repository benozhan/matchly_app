import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/coupon.dart';

class StatusBadge extends StatelessWidget {
  final CouponStatus status;
  /// When true, winning shows as "Kazandı" (past tense) for history cards.
  final bool resolved;

  const StatusBadge({super.key, required this.status, this.resolved = false});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.20), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            statusText(context, status, resolved: resolved),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

String statusText(BuildContext context, CouponStatus status, {bool resolved = false}) {
  final t = AppLocalizations.of(context)!;
  switch (status) {
    case CouponStatus.winning:   return resolved ? t.won : t.winningStatusLabel;
    case CouponStatus.risk:      return t.lost;
    case CouponStatus.pending:   return t.active;
    case CouponStatus.void_:    return t.voidStatusLabel;
    case CouponStatus.cancelled: return t.cancelledLabel;
  }
}

Color statusColor(CouponStatus status) {
  switch (status) {
    case CouponStatus.winning:   return AppColors.green;
    case CouponStatus.risk:      return AppColors.red;
    case CouponStatus.pending:   return const Color(0xFFFF9500);
    case CouponStatus.void_:    return const Color(0xFF636366);
    case CouponStatus.cancelled: return const Color(0xFF636366);
  }
}

IconData statusIcon(CouponStatus status) {
  switch (status) {
    case CouponStatus.winning:   return Icons.check_circle_outline;
    case CouponStatus.risk:      return Icons.cancel_outlined;
    case CouponStatus.pending:   return Icons.radio_button_unchecked;
    case CouponStatus.void_:    return Icons.hourglass_bottom_rounded;
    case CouponStatus.cancelled: return Icons.block_outlined;
  }
}
