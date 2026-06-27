import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/coupon_share.dart';
import '../../models/coupon.dart';
import '../home/match_row.dart';
import '../home/progress_segments.dart';
import '../home/status_badge.dart';

class GecmisPage extends StatefulWidget {
  final List<Coupon> coupons;
  final void Function(Coupon) onCouponTap;

  /// Called after a new [sharedId] is generated so the parent can persist it.
  final void Function(Coupon coupon, String sharedId)? onSharedIdGenerated;

  const GecmisPage({
    super.key,
    required this.coupons,
    required this.onCouponTap,
    this.onSharedIdGenerated,
  });

  @override
  State<GecmisPage> createState() => _GecmisPageState();
}

class _GecmisPageState extends State<GecmisPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Coupon> get _filtered {
    if (_searchQuery.isEmpty) return widget.coupons;
    final q = _searchQuery.toLowerCase();
    return widget.coupons.where((c) {
      if (c.title.toLowerCase().contains(q)) return true;
      final site = c.meta.split('·').first.trim().toLowerCase();
      if (site.contains(q)) return true;
      return c.matches.any((m) =>
          m.teams.toLowerCase().contains(q) ||
          m.selection.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final kazanan  = filtered.where((c) => c.status == CouponStatus.winning).length;
    final kaybeden = filtered.where((c) => c.status == CouponStatus.risk).length;
    final iptal    = filtered.where((c) => c.status == CouponStatus.cancelled).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        const Text(
          'Geçmiş',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),

        // ── Search bar ────────────────────────────────────────────────────────
        _GecmisSearchBar(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          onClear: () => setState(() {
            _searchQuery = '';
            _searchController.clear();
          }),
        ),
        const SizedBox(height: 14),

        // ── Summary stats card ────────────────────────────────────────────────
        _SummaryCard(
          total: filtered.length,
          kazanan: kazanan,
          kaybeden: kaybeden,
          iptal: iptal,
        ),
        const SizedBox(height: 22),

        // ── Empty state ───────────────────────────────────────────────────────
        if (filtered.isEmpty)
          _searchQuery.isNotEmpty
              ? const _SearchEmptyState()
              : const _EmptyState()
        else ...[
          ...filtered.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _HistoryCard(
                coupon: c,
                onTap: () => widget.onCouponTap(c),
                onShare: () => CouponShare.share(context, c).then(
                  (id) => widget.onSharedIdGenerated?.call(c, id),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _GecmisSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _GecmisSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Geçmişte ara...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ─── Summary stats card ───────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int total;
  final int kazanan;
  final int kaybeden;
  final int iptal;

  const _SummaryCard({
    required this.total,
    required this.kazanan,
    required this.kaybeden,
    required this.iptal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _SumStat(count: total, label: 'Kupon', color: AppColors.textSecondary),
            _SumDivider(),
            _SumStat(count: kazanan, label: 'Kazanan', color: AppColors.green),
            _SumDivider(),
            _SumStat(count: kaybeden, label: 'Kaybeden', color: AppColors.red),
            _SumDivider(),
            _SumStat(count: iptal, label: 'İptal', color: const Color(0xFF636366)),
          ],
        ),
      ),
    );
  }
}

class _SumStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SumStat({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SumDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, color: Colors.white.withOpacity(0.07));
}

// ─── History coupon card ──────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Coupon coupon;
  final VoidCallback onTap;
  final VoidCallback? onShare;

  const _HistoryCard({required this.coupon, required this.onTap, this.onShare});

  Color _potentialColor(CouponStatus status) {
    switch (status) {
      case CouponStatus.winning:   return AppColors.green;
      case CouponStatus.risk:      return AppColors.red;
      case CouponStatus.pending:   return AppColors.textSecondary;
      case CouponStatus.cancelled:
      case CouponStatus.void_: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stakeDisplay     = coupon.stake.replaceAll(' bahis', '').trim();
    final potentialDisplay = coupon.potential.replaceAll(' beklenti', '').trim();
    final oddsMatch        = RegExp(r'×([\d.,]+)').firstMatch(coupon.meta);
    final oddsDisplay      = oddsMatch != null ? '×${oddsMatch.group(1)}' : '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: coupon.status == CouponStatus.winning
                ? [const Color(0xFF1A241A), const Color(0xFF141814), const Color(0xFF0F100F)]
                : coupon.status == CouponStatus.risk
                    ? [const Color(0xFF241A1A), const Color(0xFF181414), const Color(0xFF100F0F)]
                    : coupon.status == CouponStatus.pending
                        ? [const Color(0xFF231E12), const Color(0xFF1A1710), const Color(0xFF12100C)]
                        : [const Color(0xFF1C1C22), const Color(0xFF161618), const Color(0xFF101012)],
            stops: const [0.0, 0.45, 1.0],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: coupon.status == CouponStatus.winning
                ? AppColors.green.withOpacity(0.22)
                : coupon.status == CouponStatus.risk
                    ? AppColors.red.withOpacity(0.22)
                    : coupon.status == CouponStatus.pending
                        ? const Color(0xFFFFBB00).withOpacity(0.20)
                        : Colors.white.withOpacity(0.07),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: coupon.status == CouponStatus.winning
                  ? AppColors.green.withOpacity(0.10)
                  : coupon.status == CouponStatus.risk
                      ? AppColors.red.withOpacity(0.10)
                      : coupon.status == CouponStatus.pending
                          ? const Color(0xFFFFBB00).withOpacity(0.08)
                          : Colors.black.withOpacity(0.55),
              blurRadius: 28,
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
          borderRadius: BorderRadius.circular(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                        StatusBadge(status: coupon.status, resolved: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.meta,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(height: 0.5, color: Colors.white.withOpacity(0.07)),
                    const SizedBox(height: 1),
                    ...coupon.matches.map((m) => MatchRow(match: m)),
                    const SizedBox(height: 8),
                    ProgressSegments(statuses: coupon.progress),
                  ],
                ),
              ),

              // Footer
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
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _FooterStat(label: 'BAHİS', value: stakeDisplay),
                        ),
                        _VertDivider(),
                        Expanded(
                          child: _FooterStat(label: 'ORAN', value: oddsDisplay),
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
              ),

              // Share row
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.10),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onShare,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Icon(Icons.ios_share_rounded, color: AppColors.textTertiary, size: 17),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _FooterStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 0.5, height: 28, color: Colors.white.withOpacity(0.07));
}

// ─── Empty states ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📭', style: TextStyle(fontSize: 36)),
          SizedBox(height: 14),
          Text('Henüz geçmiş kupon yok', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Yeni bir kupon oluşturduğunda burada görünecek.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔍', style: TextStyle(fontSize: 32)),
          SizedBox(height: 14),
          Text('Sonuç bulunamadı', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Farklı bir arama terimi deneyin.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}
