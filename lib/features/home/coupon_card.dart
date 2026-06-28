import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/coupon_share.dart';
import '../../models/coupon.dart';
import 'match_row.dart';
import 'progress_segments.dart';
import 'status_badge.dart';

class CouponCard extends StatefulWidget {
  final Coupon coupon;
  final VoidCallback? onTap;
  final bool isFavorite;
  final bool resolved;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const CouponCard({
    super.key,
    required this.coupon,
    this.onTap,
    this.isFavorite = false,
    this.resolved = false,
    this.onFavoriteToggle,
    this.onEdit,
    this.onDelete,
    this.onShare,
  });

  @override
  State<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<CouponCard> {
  bool _pressed = false;

  Color _potentialColor(CouponStatus status) {
    switch (status) {
      case CouponStatus.winning:   return AppColors.green;
      case CouponStatus.risk:      return AppColors.red;
      case CouponStatus.pending:   return const Color(0xFFFF9500);
      case CouponStatus.void_:    return const Color(0xFF636366);
      case CouponStatus.cancelled: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = widget.isFavorite;
    final coupon = widget.coupon;
    final stakeDisplay = coupon.stake.replaceAll(' bahis', '').trim();
    final potentialDisplay = coupon.potential.replaceAll(' beklenti', '').trim();
    final oddsMatch = RegExp(r'×([\d.,]+)').firstMatch(coupon.meta);
    final oddsDisplay = oddsMatch != null ? '×${oddsMatch.group(1)}' : '—';

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.978 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: coupon.status == CouponStatus.winning
                ? const Border(left: BorderSide(color: Color(0xFF16A34A), width: 3))
                : coupon.status == CouponStatus.risk
                    ? const Border(left: BorderSide(color: Color(0xFFDC2626), width: 3))
                    : fav
                        ? const Border(left: BorderSide(color: Color(0xFFA16207), width: 3))
                        : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x142D4A6E),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x0A2D4A6E),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card body ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (fav) ...[
                            const Icon(Icons.star_rounded,
                                color: AppColors.amber, size: 14),
                            const SizedBox(width: 5),
                          ],
                          Expanded(
                            child: Text(
                              coupon.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: coupon.status, resolved: widget.resolved),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.meta,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Divider
                      Container(
                        height: 0.5,
                        color: AppColors.border,
                      ),
                      const SizedBox(height: 1),

                      // Match rows
                      ...coupon.matches.map((m) => MatchRow(match: m)),

                      const SizedBox(height: 8),
                      ProgressSegments(statuses: coupon.progress),
                    ],
                  ),
                ),

                // ── Card footer ──
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // 3-column stats row
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: _FooterStat(
                                  label: 'BAHİS',
                                  value: stakeDisplay,
                                ),
                              ),
                              _VertDivider(),
                              Expanded(
                                child: _FooterStat(
                                  label: 'ORAN',
                                  value: oddsDisplay,
                                ),
                              ),
                              _VertDivider(),
                              Expanded(
                                child: _FooterStat(
                                  label: 'BEKLENTİ',
                                  value: potentialDisplay,
                                  valueColor: _potentialColor(coupon.status),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Actions separator
                      Container(
                        height: 0.5,
                        color: AppColors.border,
                      ),
                      // Action icons row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _ActionBtn(
                              icon: fav
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: fav
                                  ? AppColors.amber
                                  : AppColors.textTertiary,
                              onTap: widget.onFavoriteToggle,
                            ),
                            _ActionBtn(
                              icon: Icons.edit_outlined,
                              color: AppColors.textSecondary,
                              onTap: widget.onEdit,
                            ),
                            _ActionBtn(
                              icon: Icons.ios_share_rounded,
                              color: AppColors.textSecondary,
                              onTap: widget.onShare,
                            ),
                            _ActionBtn(
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.red.withOpacity(0.65),
                              onTap: widget.onDelete,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Footer helpers ──

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _FooterStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      color: AppColors.border,
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}
