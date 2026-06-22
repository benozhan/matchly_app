import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../models/coupon.dart';
import '../../services/social_service.dart';

class SharedCouponDetailPage extends StatefulWidget {
  final SharedCoupon sharedCoupon;
  final Coupon? localCoupon;
  final SocialUser? owner;

  const SharedCouponDetailPage({
    super.key,
    required this.sharedCoupon,
    this.localCoupon,
    this.owner,
  });

  @override
  State<SharedCouponDetailPage> createState() => _SharedCouponDetailPageState();
}

class _SharedCouponDetailPageState extends State<SharedCouponDetailPage> {
  CouponDetail? _detail;
  bool _fetching = false;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    if (widget.localCoupon == null) _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { _fetching = true; _fetchError = null; });
    final d = await SocialService.instance
        .getCouponDetail(widget.sharedCoupon.couponId);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _fetching = false;
      if (d == null) _fetchError = 'Kupon detayı bulunamadı';
    });
  }

  String get _shortId {
    final id = widget.sharedCoupon.couponId;
    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
      return '${dt.day} ${months[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final sharedCoupon = widget.sharedCoupon;
    final owner = widget.owner;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Back button ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Header ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.brand.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.brand.withOpacity(0.25), width: 0.5),
                          ),
                          child: const Icon(Icons.confirmation_number_outlined,
                              size: 22, color: AppColors.brand),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kupon #$_shortId',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: sharedCoupon.isPublic
                                    ? AppColors.green.withOpacity(0.12)
                                    : AppColors.textTertiary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sharedCoupon.isPublic ? 'Herkese Açık' : 'Gizli',
                                style: TextStyle(
                                  color: sharedCoupon.isPublic
                                      ? AppColors.green
                                      : AppColors.textTertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Meta section ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _MetaSection(
                  sharedCoupon: sharedCoupon,
                  owner: owner,
                  fmtDate: _fmtDate,
                ),
              ),
            ),

            // ── Local coupon details or placeholder ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: widget.localCoupon != null
                    ? _LocalDetails(coupon: widget.localCoupon!)
                    : _fetching
                        ? const _LoadingDetail()
                        : _detail != null
                            ? _FetchedDetails(detail: _detail!)
                            : _ErrorDetail(
                                error: _fetchError,
                                onRetry: _fetchDetail,
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Meta section ──────────────────────────────────────────────────────────────

class _MetaSection extends StatelessWidget {
  final SharedCoupon sharedCoupon;
  final SocialUser? owner;
  final String Function(String) fmtDate;

  const _MetaSection({
    required this.sharedCoupon,
    required this.owner,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          _MetaRow(
            label: 'Paylaşan',
            value: owner != null
                ? '${owner!.displayName} (@${owner!.username})'
                : '@bilinmiyor',
          ),
          _Divider(),
          _MetaRow(
            label: 'Tarih',
            value: fmtDate(sharedCoupon.createdAt),
          ),
          _Divider(),
          _MetaRow(
            label: 'Durum',
            value: sharedCoupon.isPublic ? 'Herkese Açık' : 'Gizli',
            valueColor: sharedCoupon.isPublic ? AppColors.green : AppColors.textTertiary,
          ),
          _Divider(),
          _CopyableRow(
            label: 'Kupon ID',
            value: sharedCoupon.couponId,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kopyalandı',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            backgroundColor: const Color(0xFF1C1C1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace'),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.copy_rounded,
                size: 13, color: AppColors.textTertiary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Container(height: 0.5, color: Colors.white.withOpacity(0.06)),
      );
}

// ── Local coupon details ───────────────────────────────────────────────────────

class _LocalDetails extends StatelessWidget {
  final Coupon coupon;
  const _LocalDetails({required this.coupon});

  String get _siteName {
    final parts = coupon.meta.split('·');
    return parts.first.trim();
  }

  String get _oddsDisplay {
    final m = RegExp(r'×([\d.,]+)').firstMatch(coupon.meta);
    return m != null ? '×${m.group(1)}' : '—';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + site
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    _siteName,
                    style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _MiniStat(label: 'Bahis',    value: coupon.stake),
                const SizedBox(width: 20),
                _MiniStat(label: 'Oran',     value: _oddsDisplay),
                const SizedBox(width: 20),
                _MiniStat(label: 'Beklenti', value: coupon.potential),
              ],
            ),
          ),
          // Selections
          if (coupon.matches.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Divider(height: 1, thickness: 0.5,
                  color: Colors.white.withOpacity(0.06)),
            ),
            ...coupon.matches.map(
              (m) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(m.teams,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(m.selection,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Fetched coupon details ────────────────────────────────────────────────────

class _FetchedDetails extends StatelessWidget {
  final CouponDetail detail;
  const _FetchedDetails({required this.detail});

  Color _statusColor(String s) {
    switch (s) {
      case 'winning':  return AppColors.green;
      case 'risk':     return AppColors.red;
      case 'cancelled': return AppColors.textTertiary;
      default:         return AppColors.brand;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'winning':   return 'Kazanıyor';
      case 'risk':      return 'Risk';
      case 'pending':   return 'Bekliyor';
      case 'cancelled': return 'İptal';
      default:          return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + site + status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    detail.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                if (detail.siteName.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      detail.siteName,
                      style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          // Status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(detail.status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                _statusLabel(detail.status),
                style: TextStyle(
                    color: _statusColor(detail.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // Stats row
          if (detail.stake.isNotEmpty || detail.odds.isNotEmpty || detail.potential.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  if (detail.stake.isNotEmpty) ...[
                    _MiniStat(label: 'Bahis', value: detail.stake),
                    const SizedBox(width: 20),
                  ],
                  if (detail.odds.isNotEmpty) ...[
                    _MiniStat(label: 'Oran', value: detail.odds),
                    const SizedBox(width: 20),
                  ],
                  if (detail.potential.isNotEmpty)
                    _MiniStat(label: 'Beklenti', value: detail.potential),
                ],
              ),
            ),
          // Selections
          if (detail.selections.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Divider(height: 1, thickness: 0.5,
                  color: Colors.white.withOpacity(0.06)),
            ),
            ...detail.selections.map((s) => _SelectionCard(sel: s)),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Selection card ────────────────────────────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  final CouponSelection sel;
  const _SelectionCard({required this.sel});

  Color _statusColor(String s) {
    switch (s) {
      case 'winning':   return AppColors.green;
      case 'risk':      return AppColors.red;
      case 'cancelled': return AppColors.textTertiary;
      default:          return AppColors.brand;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'winning':   return 'Kazandı';
      case 'risk':      return 'Kaybetti';
      case 'pending':   return 'Bekliyor';
      case 'cancelled': return 'İptal';
      default:          return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match name + status
          Row(
            children: [
              Expanded(
                child: Text(
                  sel.matchName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(sel.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _statusLabel(sel.status),
                  style: TextStyle(
                      color: _statusColor(sel.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          // Bet type + score
          Row(
            children: [
              Text(
                sel.betType,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              if (sel.lastScore.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  'Skor: ${sel.lastScore}',
                  style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Loading / error states ────────────────────────────────────────────────────

class _LoadingDetail extends StatelessWidget {
  const _LoadingDetail();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
      ),
      child: const Center(
        child: CircularProgressIndicator(
            color: AppColors.brand, strokeWidth: 2),
      ),
    );
  }
}

class _ErrorDetail extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  const _ErrorDetail({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 32, color: AppColors.textTertiary.withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(
            error ?? 'Kupon detayı yüklenemedi',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.brand.withOpacity(0.3), width: 0.5),
              ),
              child: const Text('Tekrar Dene',
                  style: TextStyle(
                      color: AppColors.brand,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
