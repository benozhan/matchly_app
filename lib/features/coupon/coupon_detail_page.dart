import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../services/comment_service.dart';

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

  BoxDecoration _cardDecoration([CouponStatus? status]) => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: status == CouponStatus.winning
            ? const Border(left: BorderSide(color: Color(0xFF16A34A), width: 3))
            : status == CouponStatus.risk
                ? const Border(left: BorderSide(color: Color(0xFFDC2626), width: 3))
                : Border.all(color: AppColors.border, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142D4A6E),
            blurRadius: 20,
            offset: Offset(0, 4),
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

                      // ── Hero card (4. tasarım) ────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(color: Color(0x402D4A6E), blurRadius: 24, offset: Offset(0, 8)),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.coupon.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: StatusBadge(status: _status, resolved: widget.resolved),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.coupon.meta,
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: _HeroStat(label: 'BAHİS', value: stakeDisplay)),
                                Container(width: 0.5, height: 36, color: Colors.white.withOpacity(0.2)),
                                Expanded(child: _HeroStat(label: 'ORAN', value: oddsDisplay)),
                                Container(width: 0.5, height: 36, color: Colors.white.withOpacity(0.2)),
                                Expanded(child: _HeroStat(label: 'BEKLENTİ', value: potDisplay,
                                  highlight: _status == CouponStatus.winning)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Builder(builder: (context) {
                              final done = widget.coupon.progress.where((s) => s != CouponStatus.pending).length;
                              final total = widget.coupon.progress.length;
                              final ratio = total > 0 ? done / total : 0.0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      backgroundColor: Colors.white.withOpacity(0.15),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _status == CouponStatus.risk ? AppColors.red : Colors.white,
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$done/$total tamamlandı',
                                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Matches card ──────────────────────────────────────
                      Container(
                        decoration: _cardDecoration(widget.coupon.status),
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
                        decoration: _cardDecoration(widget.coupon.status),
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
                          decoration: _cardDecoration(widget.coupon.status),
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

                      // ── Yorumlar ─────────────────────────────────────
                      const SizedBox(height: 24),
                      _CouponComments(couponId: widget.coupon.id ?? ''),
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

// ─── Yorumlar widget ──────────────────────────────────────────────────────────

String _fmtTimeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  return '${dt.day}.${dt.month}.${dt.year}';
}

class _CouponComments extends StatefulWidget {
  final String couponId;
  const _CouponComments({required this.couponId});

  @override
  State<_CouponComments> createState() => _CouponCommentsState();
}

class _CouponCommentsState extends State<_CouponComments> {
  List<CouponComment> _comments = [];
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.couponId.isEmpty) return;
    final comments = await CommentService.instance.getComments(widget.couponId);
    if (mounted) setState(() => _comments = comments);
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      String username = 'user';
      if (uid != null) {
        try {
          final res = await Supabase.instance.client
              .from('profiles').select('username').eq('id', uid).single();
          username = res['username'] as String? ?? 'user';
        } catch (_) {}
      }
      await CommentService.instance.addComment(widget.couponId, username, text);
      _ctrl.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Yorumlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ..._comments.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('@${c.username}', style: const TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(_fmtTimeAgo(c.createdAt), style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  const Spacer(),
                  if (c.userId == currentUserId)
                    GestureDetector(
                      onTap: () async {
                        await CommentService.instance.deleteComment(c.id);
                        _load();
                      },
                      child: const Icon(Icons.delete_outline, size: 16, color: AppColors.textTertiary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(c.content, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ],
          ),
        )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Yorum yaz...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border, width: 0.5)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border, width: 0.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _loading ? null : _submit,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(10)),
                child: _loading
                    ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
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
      (CouponStatus.pending,   'Aktif',    Icons.radio_button_unchecked, AppColors.textSecondary),
      (CouponStatus.winning,   'Kazandı',  Icons.check_circle_outline,   AppColors.green),
      (CouponStatus.risk,      'Kaybetti', Icons.cancel_outlined,         AppColors.red),
      (CouponStatus.cancelled, 'İptal',    Icons.block_outlined,          AppColors.textTertiary),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.border, width: 0.5),
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
                color: AppColors.border,
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
              child: Container(height: 0.5, color: AppColors.border),
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
          child: Container(height: 0.5, color: AppColors.border),
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
        color: AppColors.border,
      );
}


class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _HeroStat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF86EFAC) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}