import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/coupon_share.dart';
import '../../models/coupon.dart';
import '../home/match_row.dart';
import '../home/progress_segments.dart';
import '../home/status_badge.dart';
import '../shared_coupon/shared_coupon_preview_page.dart';

class CouponDetailPage extends StatefulWidget {
  final Coupon coupon;
  /// When true, winning badge reads "Kazandı" (history context).
  final bool resolved;
  /// Called after a new sharedId is generated so the parent can persist it.
  final void Function(String sharedId)? onSharedIdGenerated;
  /// All coupons — passed to SharedCouponPreviewPage for mock lookup.
  /// TODO: Remove once SharedCouponPreviewPage fetches remotely.
  final List<Coupon> allCoupons;
  /// Called when the user manually changes the coupon status.
  final void Function(CouponStatus)? onStatusChanged;

  const CouponDetailPage({
    super.key,
    required this.coupon,
    this.resolved = false,
    this.onSharedIdGenerated,
    this.allCoupons = const [],
    this.onStatusChanged,
  });

  @override
  State<CouponDetailPage> createState() => _CouponDetailPageState();
}

class _CouponDetailPageState extends State<CouponDetailPage> {
  late CouponStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.coupon.status;
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Color _potentialColor(CouponStatus s) {
    switch (s) {
      case CouponStatus.winning:   return AppColors.green;
      case CouponStatus.risk:      return AppColors.red;
      case CouponStatus.pending:   return AppColors.textPrimary;
      case CouponStatus.cancelled:
      case CouponStatus.void_: return AppColors.textTertiary;
    }
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.50),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      );

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StatusSheet(
        currentStatus: _status,
        onSelect: (s) {
          setState(() => _status = s);
          widget.onStatusChanged?.call(s);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stakeDisplay = widget.coupon.stake.replaceAll(' bahis', '').trim();
    final potDisplay   = widget.coupon.potential.replaceAll(' beklenti', '').trim();
    final oddsMatch    = RegExp(r'×([\d.,]+)').firstMatch(widget.coupon.meta);
    final oddsDisplay  = oddsMatch != null ? '×${oddsMatch.group(1)}' : '—';
    final selCount     = '${widget.coupon.matches.length}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: Column(
              children: [

                // ── Nav bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => CouponShare.share(context, widget.coupon)
                            .then((id) => widget.onSharedIdGenerated?.call(id)),
                        icon: const Icon(
                          Icons.ios_share_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      // Preview button — shown once a sharedId exists.
                      // TODO(deep-links): Remove once real link routing is live.
                      if (widget.coupon.sharedId != null)
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SharedCouponPreviewPage(
                                sharedId: widget.coupon.sharedId!,
                                allCoupons: widget.allCoupons,
                              ),
                            ),
                          ),
                          tooltip: 'Önizleme',
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            color: AppColors.textTertiary,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    children: [

                      // ── Hero card ─────────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF222228),
                              Color(0xFF1A1A1E),
                              Color(0xFF131316),
                            ],
                            stops: [0.0, 0.45, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.55),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                              spreadRadius: -6,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.20),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title + badge row
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.coupon.title,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 3),
                                          child: StatusBadge(
                                            status: _status,
                                            resolved: widget.resolved,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.coupon.meta,
                                      style: const TextStyle(
                                        color: AppColors.textTertiary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Hero footer — BAHİS / ORAN / BEKLENTİ
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.15),
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.white.withOpacity(0.06),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: IntrinsicHeight(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _DetailStat(
                                            label: 'BAHİS',
                                            value: stakeDisplay,
                                          ),
                                        ),
                                        _DetailVertDivider(),
                                        Expanded(
                                          child: _DetailStat(
                                            label: 'ORAN',
                                            value: oddsDisplay,
                                          ),
                                        ),
                                        _DetailVertDivider(),
                                        Expanded(
                                          child: _DetailStat(
                                            label: 'BEKLENTİ',
                                            value: potDisplay,
                                            valueColor: _potentialColor(_status),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Progress ──────────────────────────────────────────
                      ProgressSegments(statuses: widget.coupon.progress),

                      const SizedBox(height: 16),

                      // ── Matches card ──────────────────────────────────────
                      Container(
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                              child: Text(
                                'MAÇLAR',
                                style: TextStyle(
                                  color: AppColors.textTertiary.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Container(
                                height: 0.5,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                              child: Column(
                                children: widget.coupon.matches
                                    .map((m) => MatchRow(match: m))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Bottom stats — TOPLAM SEÇİM / TOPLAM ORAN / BEKLENTİ
                      Container(
                        decoration: _cardDecoration(),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  child: _DetailStat(
                                    label: 'TOPLAM SEÇİM',
                                    value: selCount,
                                  ),
                                ),
                              ),
                              _DetailVertDivider(),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                       child: _DetailStat(
                                    label: 'BEKLENTİ',
                                    value: potDisplay,
                                    valueColor: _potentialColor(_status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Manual status update ──────────────────────────────
                      GestureDetector(
                        onTap: _showStatusSheet,
                        child: Container(
                          decoration: _cardDecoration(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.swap_horiz_rounded,
                                color: AppColors.textTertiary,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Durumu Değiştir',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                status: _status,
                                resolved: widget.resolved,
                              ),
                            ],
                          ),
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

// ─── Status bottom sheet ──────────────────────────────────────────────────────

class _StatusSheet extends StatelessWidget {
  final CouponStatus currentStatus;
  final ValueChanged<CouponStatus> onSelect;

  const _StatusSheet({required this.currentStatus, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const rows = [
      (CouponStatus.pending,   'Aktif',    Icons.radio_button_unchecked, Color(0xFF8E8E93)),
      (CouponStatus.winning,   'Kazandı',  Icons.check_circle_outline,   AppColors.green),
      (CouponStatus.risk,      'Kaybetti', Icons.cancel_outlined,         AppColors.red),
      (CouponStatus.cancelled, 'İptal',    Icons.block_outlined,          Color(0xFF636366)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Durumu Değiştir',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(height: 0.5, color: Colors.white.withOpacity(0.07)),
            ),
            ...rows.map((r) {
              final (status, label, icon, color) = r;
              final isSelected = currentStatus == status;
              return _StatusRow(
                label: label,
                icon: icon,
                color: color,
                isSelected: isSelected,
                onTap: () => onSelect(status),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded, color: color, size: 18),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(height: 0.5, color: Colors.white.withOpacity(0.05)),
        ),
      ],
    );
  }
}

// ─── Shared stat/divider helpers ──────────────────────────────────────────────

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _DetailVertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 0.5,
        color: Colors.white.withOpacity(0.07),
      );
}
