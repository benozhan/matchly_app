import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/coupon.dart';
import '../home/match_row.dart';
import '../home/progress_segments.dart';
import '../home/status_badge.dart';

// TODO(deep-links): Replace allCoupons lookup with a network fetch keyed on
//   sharedId once the backend exists. The page contract stays the same —
//   just swap the synchronous lookup for an async loader.
// TODO(live-shared-coupon): Replace the placeholder card with a real-time
//   WebSocket feed that streams selection status updates to the viewer.

class SharedCouponPreviewPage extends StatelessWidget {
  /// The sharedId extracted from the deep link (e.g. matchly.app/coupon/{id}).
  final String sharedId;

  /// All locally available coupons. Used for mock lookup until backend exists.
  ///
  /// TODO: Remove once the page fetches from a remote source.
  final List<Coupon> allCoupons;

  const SharedCouponPreviewPage({
    super.key,
    required this.sharedId,
    required this.allCoupons,
  });

  Coupon? _resolve() {
    try {
      return allCoupons.firstWhere((c) => c.sharedId == sharedId);
    } catch (_) {
      return null;
    }
  }

  Color _potentialColor(CouponStatus status) {
    switch (status) {
      case CouponStatus.winning:   return AppColors.green;
      case CouponStatus.risk:      return AppColors.red;
      case CouponStatus.pending:   return AppColors.textPrimary;
      case CouponStatus.cancelled:
      case CouponStatus.void_: return AppColors.textTertiary;
    }
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.50),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final coupon = _resolve();

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
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Paylaşılan Kupon',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ──────────────────────────────────────────────────
                Expanded(
                  child: coupon == null
                      ? const _NotFoundState()
                      : _CouponPreviewBody(
                          coupon: coupon,
                          potentialColor: _potentialColor(coupon.status),
                          cardDeco: _cardDeco(),
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

// ─── Found: coupon preview ────────────────────────────────────────────────────

class _CouponPreviewBody extends StatelessWidget {
  final Coupon coupon;
  final Color potentialColor;
  final BoxDecoration cardDeco;

  const _CouponPreviewBody({
    required this.coupon,
    required this.potentialColor,
    required this.cardDeco,
  });

  @override
  Widget build(BuildContext context) {
    final site      = coupon.meta.split('·').first.trim();
    final stakeDisplay = coupon.stake.replaceAll(' bahis', '').trim();
    final potDisplay   = coupon.potential.replaceAll(' beklenti', '').trim();
    final oddsMatch    = RegExp(r'×([\d.,]+)').firstMatch(coupon.meta);
    final oddsDisplay  = oddsMatch != null ? '×${oddsMatch.group(1)}' : '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
      children: [

        // ── Hero card ─────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardHigh,
                AppColors.card,
                Color(0xFF131316),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.border,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.border,
                blurRadius: 32,
                offset: const Offset(0, 14),
                spreadRadius: -6,
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
                      // Title + badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              coupon.title,
                              style: TextStyle(
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
                              status: coupon.status,
                              resolved: coupon.status != CouponStatus.pending,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Site name
                      Text(
                        site,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer: BAHİS / ORAN / BEKLENTİ
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border,
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
                            child: _Stat(label: 'BAHİS', value: stakeDisplay),
                          ),
                          _VertDivider(),
                          Expanded(
                            child: _Stat(label: 'ORAN', value: oddsDisplay),
                          ),
                          _VertDivider(),
                          Expanded(
                            child: _Stat(
                              label: 'BEKLENTİ',
                              value: potDisplay,
                              valueColor: potentialColor,
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

        // ── Progress ──────────────────────────────────────────────────────
        ProgressSegments(statuses: coupon.progress),

        const SizedBox(height: 16),

        // ── Matches card ──────────────────────────────────────────────────
        Container(
          decoration: cardDeco,
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
                  color: AppColors.border,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                child: Column(
                  children: coupon.matches.map((m) => MatchRow(match: m)).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Live tracking placeholder ─────────────────────────────────────
        // TODO(live-shared-coupon): Replace with a real-time feed widget
        //   once WebSocket / Firestore stream is wired to sharedId.
        _LiveTrackingPlaceholder(),
      ],
    );
  }
}

// ─── Live tracking placeholder card ──────────────────────────────────────────

class _LiveTrackingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.green.withOpacity(0.18),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.border,
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing icon container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.green.withOpacity(0.20),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.wifi_rounded,
              color: AppColors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Canlı takip yakında aktif olacak',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Maç sonuçları bu ekranda gerçek zamanlı güncellenecek.',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.green.withOpacity(0.22),
                width: 0.5,
              ),
            ),
            child: Text(
              'Yakında',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Not found state ──────────────────────────────────────────────────────────

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.link_off_rounded,
              color: AppColors.textTertiary,
              size: 28,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Kupon bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu bağlantı geçersiz veya süresi dolmuş olabilir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _Stat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
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

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 0.5,
        color: AppColors.border,
      );
}
