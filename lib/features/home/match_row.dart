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
            isPending ? Icons.radio_button_unchecked : statusIcon(match.status),
            color: isPending
                ? AppColors.amber
                : statusColor(match.status).withOpacity(0.85),
            size: 16,
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

  Color _teamColor() {
    final colors = [
      const Color(0xFF2D4A6E), const Color(0xFF16A34A), const Color(0xFFDC2626),
      const Color(0xFFA16207), const Color(0xFF7C3AED), const Color(0xFF0891B2),
      const Color(0xFFBE185D), const Color(0xFF065F46), const Color(0xFF92400E),
    ];
    int hash = 0;
    for (var ch in abbrev.codeUnits) { hash = (hash * 31 + ch) & 0xFFFFFF; }
    return colors[hash % colors.length];
  }

  Widget build(BuildContext context) {
    final bgColor = _teamColor();
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dimmed ? bgColor.withOpacity(0.4) : bgColor,
      ),
      child: Center(
        child: Text(
          abbrev,
          style: TextStyle(
            color: Colors.white,
            fontSize: abbrev.length > 2 ? 5.5 : 7,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
