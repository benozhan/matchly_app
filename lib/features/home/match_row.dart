import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/coupon.dart';
import 'selection_pill.dart';
import 'status_badge.dart';

class MatchRow extends StatelessWidget {
  final MatchItem match;

  const MatchRow({
    super.key,
    required this.match,
  });

  // ≤3-char abbreviation: short names kept as-is, longer names take first 3 chars.
  static String _abbrev(String name) {
    final w = name.trim();
    return w.length <= 3 ? w.toUpperCase() : w.substring(0, 3).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = match.status == CouponStatus.pending;
    final isVoid = match.status == CouponStatus.void_;

    final parts = match.teams.split(' – ');
    final homeName   = parts.isNotEmpty ? parts[0].trim() : match.teams;
    final awayName   = parts.length > 1  ? parts[1].trim() : '';
    final homeAbbrev = _abbrev(homeName);
    final awayAbbrev = _abbrev(awayName.isNotEmpty ? awayName : homeName);

    final nameStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── [GS] GS – FB [FB] ─────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Home avatar
                _MiniAvatar(abbrev: homeAbbrev, dimmed: isPending),
                const SizedBox(width: 4),
                // Home name — shrinks first if tight
                Flexible(
                  child: Text(
                    homeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle,
                  ),
                ),
                // Separator — always visible, no extra spacing
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '–',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                // Away name — shrinks if tight
                Flexible(
                  child: Text(
                    awayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle,
                  ),
                ),
                const SizedBox(width: 4),
                // Away avatar — trails the away name
                _MiniAvatar(abbrev: awayAbbrev, dimmed: isPending),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── Selection pill ─────────────────────────────────────
          SelectionPill(text: match.selection, dimmed: isPending),
          const SizedBox(width: 8),

          // ── Score ──────────────────────────────────────────────
          SizedBox(
            width: 30,
            child: Text(
              match.score,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 5),

          // ── Time ───────────────────────────────────────────────
          SizedBox(
            width: 34,
            child: Text(
              match.minute,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 5),

          // ── Status icon ────────────────────────────────────────
          Icon(
            statusIcon(match.status),
            color: isPending
                ? AppColors.textSecondary.withOpacity(0.50)
                : statusColor(match.status).withOpacity(0.85),
            size: 12,
          ),
        ],
      ),
    );
  }
}

// ── Mini avatar ────────────────────────────────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  final String abbrev;
  final bool dimmed;

  const _MiniAvatar({required this.abbrev, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.border,
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Text(
          abbrev,
          style: TextStyle(
            color: dimmed
                ? AppColors.textSecondary.withOpacity(0.50)
                : AppColors.textSecondary,
            fontSize: abbrev.length > 2 ? 5.5 : 6.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
