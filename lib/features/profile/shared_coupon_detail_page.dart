import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../models/coupon.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/comment_service.dart';
import '../shared/reaction_bar.dart';
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
  List<CouponComment> _comments = [];
  final _commentCtrl = TextEditingController();
  bool _commentLoading = false;
  bool _silentRefreshing = false;
  String? _fetchError;
  Timer? _timer;

  static const _kRefreshInterval = Duration(seconds: 15);
  static const _kMaxWidth = 430.0;

  @override
  void initState() {
    super.initState();
    if (widget.localCoupon == null) {
      _fetchDetail();
      _timer = Timer.periodic(_kRefreshInterval, (_) => _silentRefresh());
    }
    _loadComments();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commentCtrl.dispose();
    super.dispose();
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

  Future<void> _silentRefresh() async {
    if (_silentRefreshing || _fetching) return;
    setState(() => _silentRefreshing = true);
    final d = await SocialService.instance
        .getCouponDetail(widget.sharedCoupon.couponId);
    if (!mounted) return;
    setState(() {
      if (d != null) _detail = d;
      _silentRefreshing = false;
    });
  }

  String get _shortId {
    final id = widget.sharedCoupon.couponId;
    return id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  Future<void> _loadComments() async {
    final couponId = widget.sharedCoupon.couponId;
    try {
      final comments = await CommentService.instance.getComments(couponId);
      if (mounted) setState(() => _comments = comments);
    } catch (_) {}
  }

  String? _replyToCommentId;
  String? _replyToUsername;

  void _startReply(String commentId, String username) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUsername = username;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });
  }

  Future<void> _submitComment(String username) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _commentLoading = true);
    try {
      await CommentService.instance.addComment(
        widget.sharedCoupon.couponId,
        username,
        text,
        parentCommentId: _replyToCommentId,
      );
      _commentCtrl.clear();
      _replyToCommentId = null;
      _replyToUsername = null;
      await _loadComments();
    } catch (_) {} finally {
      if (mounted) setState(() => _commentLoading = false);
    }
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final sharedCoupon = widget.sharedCoupon;
    final owner = widget.owner;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brand,
          backgroundColor: AppColors.card,
          onRefresh: widget.localCoupon == null ? _silentRefresh : () async {},
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxWidth),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [

                  // ── Nav bar ────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 14, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 18, color: AppColors.textSecondary),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          if (widget.localCoupon == null)
                            SizedBox(
                              width: 36, height: 36,
                              child: _silentRefreshing
                                  ? Padding(
                                      padding: const EdgeInsets.all(9),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.textTertiary),
                                    )
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.refresh_rounded,
                                          size: 18, color: AppColors.textTertiary),
                                      onPressed: _silentRefresh,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Header ─────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.brand.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppColors.brand.withOpacity(0.25),
                                  width: 0.5),
                            ),
                            child: Icon(Icons.confirmation_number_outlined,
                                size: 22, color: AppColors.brand),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kupon #$_shortId',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sharedCoupon.isPublic
                                        ? AppColors.green.withOpacity(0.12)
                                        : AppColors.textTertiary
                                            .withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    sharedCoupon.isPublic
                                        ? 'Herkese Açık'
                                        : 'Gizli',
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
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Meta card ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _MetaSection(
                        sharedCoupon: sharedCoupon,
                        owner: owner,
                        detail: _detail,
                        fmtDate: _fmtDate,
                      ),
                    ),
                  ),

                  // ── Coupon detail card ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

                  // ── Beğeni ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: ReactionBar(couponId: widget.sharedCoupon.couponId),
                    ),
                  ),

                  // ── Yorumlar ───────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomPad),
                      child: _CommentsSection(
                        comments: _comments,
                        ctrl: _commentCtrl,
                        loading: _commentLoading,
                        currentUserId: Supabase.instance.client.auth.currentUser?.id ?? '',
                        replyToCommentId: _replyToCommentId,
                        replyToUsername: _replyToUsername,
                        onReply: _startReply,
                        onCancelReply: _cancelReply,
                        onSubmit: () async {
                          final uid = Supabase.instance.client.auth.currentUser?.id;
                          String username = 'user';
                          if (uid != null) {
                            try {
                              final res = await Supabase.instance.client
                                  .from('profiles')
                                  .select('username')
                                  .eq('id', uid)
                                  .single();
                              username = res['username'] as String? ?? 'user';
                            } catch (_) {}
                          }
                          _submitComment(username);
                        },
                        onDelete: (id) async {
                          await CommentService.instance.deleteComment(id);
                          _loadComments();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  return '${dt.day}.${dt.month}.${dt.year}';
}

class _CommentsSection extends StatelessWidget {
  final List<CouponComment> comments;
  final TextEditingController ctrl;
  final bool loading;
  final String currentUserId;
  final String? replyToCommentId;
  final String? replyToUsername;
  final void Function(String id, String username) onReply;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;
  final Future<void> Function(String id) onDelete;

  const _CommentsSection({
    required this.comments,
    required this.ctrl,
    required this.loading,
    required this.currentUserId,
    required this.replyToCommentId,
    required this.replyToUsername,
    required this.onReply,
    required this.onCancelReply,
    required this.onSubmit,
    required this.onDelete,
  });

  Widget _buildCommentCard(CouponComment comment, {bool isReply = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8, left: isReply ? 24 : 0),
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
              Text('@${comment.username}', style: TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text(_timeAgo(comment.createdAt), style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              const Spacer(),
              if (comment.userId == currentUserId)
                GestureDetector(
                  onTap: () => onDelete(comment.id),
                  child: Icon(Icons.delete_outline, size: 16, color: AppColors.textTertiary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.content, style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => onReply(comment.id, comment.username),
            child: Text('Yanıtla', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topLevel = comments.where((c) => c.parentCommentId == null).toList();
    final repliesByParent = <String, List<CouponComment>>{};
    for (final c in comments) {
      if (c.parentCommentId != null) {
        repliesByParent.putIfAbsent(c.parentCommentId!, () => []).add(c);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yorumlar', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          Text('Henüz yorum yok.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ...topLevel.expand((comment) => [
          _buildCommentCard(comment),
          ...(repliesByParent[comment.id] ?? []).map((reply) => _buildCommentCard(reply, isReply: true)),
        ]),
        const SizedBox(height: 12),
        if (replyToCommentId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('@${replyToUsername ?? ''} yanıtlanıyor', style: TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCancelReply,
                  child: Icon(Icons.close, size: 14, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: replyToCommentId != null ? 'Yanıt yaz...' : 'Yorum yaz...',
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: loading ? null : onSubmit,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(12)),
                child: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Meta section ──────────────────────────────────────────────────────────────

class _MetaSection extends StatelessWidget {
  final SharedCoupon sharedCoupon;
  final SocialUser? owner;
  final CouponDetail? detail;
  final String Function(String) fmtDate;

  const _MetaSection({
    required this.sharedCoupon,
    required this.owner,
    this.detail,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                : detail != null
                    ? '${detail!.ownerDisplayName} (@${detail!.ownerUsername})'
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
            valueColor: sharedCoupon.isPublic
                ? AppColors.green
                : AppColors.textTertiary,
          ),
          if (sharedCoupon.note.isNotEmpty) ...[
            _Divider(),
            _MetaRow(
              label: 'Not',
              value: sharedCoupon.note,
            ),
          ],
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
                style: TextStyle(
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
            content: Text('Kopyalandı',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
            backgroundColor: AppColors.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
                  style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
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
                size: 13,
                color: AppColors.textTertiary.withOpacity(0.6)),
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
        child: Container(
            height: 0.5, color: AppColors.border),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 14,
            offset: const Offset(0, 5),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    _siteName,
                    style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _MiniStat(label: 'Bahis', value: coupon.stake),
                const SizedBox(width: 24),
                _MiniStat(label: 'Oran', value: _oddsDisplay),
                const SizedBox(width: 24),
                _MiniStat(label: 'Beklenti', value: coupon.potential),
              ],
            ),
          ),
          if (coupon.matches.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.border),
            ),
            ...coupon.matches.map(
              (m) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(m.teams,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(m.selection,
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
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
            style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
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
      case 'winning':   return AppColors.green;
      case 'risk':      return AppColors.red;
      case 'cancelled': return AppColors.textTertiary;
      default:          return AppColors.brand;
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 14,
            offset: const Offset(0, 5),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + site badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    detail.title,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                if (detail.siteName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      detail.siteName,
                      style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
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
          if (detail.stake.isNotEmpty ||
              detail.odds.isNotEmpty ||
              detail.potential.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  if (detail.stake.isNotEmpty) ...[
                    _MiniStat(label: 'Bahis', value: detail.stake),
                    const SizedBox(width: 24),
                  ],
                  if (detail.odds.isNotEmpty) ...[
                    _MiniStat(label: 'Oran', value: detail.odds),
                    const SizedBox(width: 24),
                  ],
                  if (detail.potential.isNotEmpty)
                    _MiniStat(label: 'Beklenti', value: detail.potential),
                ],
              ),
            ),
          // Selections
          if (detail.selections.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.border),
            ),
            ...detail.selections.map((s) => _SelectionCard(sel: s)),
          ],
          const SizedBox(height: 18),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sel.matchName,
                  style: TextStyle(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          Row(
            children: [
              Text(
                sel.betType,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              if (sel.lastScore.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  'Skor: ${sel.lastScore}',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Center(
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border, width: 0.5),
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
            style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.brand.withOpacity(0.3), width: 0.5),
              ),
              child: Text('Tekrar Dene',
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
