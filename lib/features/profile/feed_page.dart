import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/social_service.dart';
import 'profile_page.dart';
import 'shared_coupon_detail_page.dart';
import 'user_search_page.dart';

class FeedPage extends StatefulWidget {
  final String username;
  /// Set to true when FeedPage is pushed as a route (e.g. from ProfilePage).
  /// Set to false (default) when embedded in the home bottom-nav body —
  /// in that case there is no route to pop and the back button must be hidden
  /// to prevent accidentally popping the home route (which causes a blank screen).
  final bool showBack;

  const FeedPage({
    super.key,
    required this.username,
    this.showBack = false,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<FeedItem> _items = [];
  bool _loading = true;
  String? _error;
  bool? _hasFollowing;
  SocialUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_items.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      try {
        _currentUser = await SocialService.instance.getUser(widget.username);
      } catch (_) {}

      List<FeedItem> items = [];
      try {
        items = await SocialService.instance.getFeed(widget.username);
      } catch (_) {}

      bool? hasFollowing;

      if (items.isEmpty) {
        try {
          final following =
              await SocialService.instance.getFollowing(widget.username);
          hasFollowing = following.isNotEmpty;

          if (following.isNotEmpty) {
            final built = <FeedItem>[];
            for (final u in following) {
              try {
                final coupons =
                    await SocialService.instance.getSharedCoupons(u.username);
                for (final c in coupons) {
                  built.add(FeedItem(
                    type: 'SHARED_COUPON',
                    username: u.username,
                    displayName: u.displayName,
                    couponId: c.couponId,
                    createdAt: c.createdAt,
                  ));
                }
              } catch (_) {}
            }
            built.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            items = built;
          }
        } catch (_) {
          hasFollowing = null;
        }

        if (items.isEmpty && _currentUser != null) {
          try {
            final own = await SocialService.instance
                .getSharedCoupons(widget.username);
            if (own.isNotEmpty) {
              final u = _currentUser!;
              items = own
                  .map((c) => FeedItem(
                        type: 'SHARED_COUPON',
                        username: u.username,
                        displayName: u.displayName,
                        couponId: c.couponId,
                        createdAt: c.createdAt,
                      ))
                  .toList();
              items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            }
          } catch (_) {}
        }
      } else {
        hasFollowing = true;
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _hasFollowing = hasFollowing;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openSearch() {
    if (_currentUser == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => UserSearchPage(currentUser: _currentUser!),
    ));
  }

  void _openProfile(String username) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProfilePage(
        username: username,
        currentUsername: widget.username,
      ),
    ));
  }

  void _openDetail(FeedItem item) {
    final sc = SharedCoupon(
      id: item.couponId,
      couponId: item.couponId,
      isPublic: true,
      createdAt: item.createdAt,
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SharedCouponDetailPage(sharedCoupon: sc),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      widget.showBack ? 4 : 16, 14, 16, 0),
                  child: Row(
                    children: [
                      if (widget.showBack)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      const Spacer(),
                      if (!_loading)
                        GestureDetector(
                          onTap: _load,
                          child: const Icon(Icons.refresh_rounded,
                              size: 20, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),

                // ── Large title ──────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 2),
                  child: Text(
                    'Akış',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    'Takip ettiğin kullanıcıların paylaşımları',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                // ── Search card ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: GestureDetector(
                    onTap: _currentUser != null ? _openSearch : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.07), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: _currentUser != null
                                ? AppColors.textSecondary
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kullanıcı ara...',
                            style: TextStyle(
                              color: _currentUser != null
                                  ? AppColors.textSecondary
                                  : AppColors.textTertiary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Body ─────────────────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.brand, strokeWidth: 2))
                      : _error != null
                          ? _ErrorBody(error: _error!, onRetry: _load)
                          : _items.isEmpty
                              ? _EmptyBody(
                                  hasFollowing: _hasFollowing,
                                  onSearchTap:
                                      _currentUser != null ? _openSearch : null,
                                )
                              : RefreshIndicator(
                                  color: AppColors.brand,
                                  backgroundColor: AppColors.card,
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 4, 16, 40),
                                    itemCount: _items.length,
                                    itemBuilder: (context, i) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _FeedCard(
                                        item: _items[i],
                                        onTap: () => _openDetail(_items[i]),
                                        onProfileTap: () =>
                                            _openProfile(_items[i].username),
                                      ),
                                    ),
                                  ),
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

// ── Feed card (fetches CouponDetail for rich display) ─────────────────────────

class _FeedCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;

  const _FeedCard({
    required this.item,
    required this.onTap,
    required this.onProfileTap,
  });

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  CouponDetail? _detail;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final d = await SocialService.instance
          .getCouponDetail(widget.item.couponId);
      if (mounted) setState(() { _detail = d; _fetching = false; });
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'şimdi';
      if (diff.inMinutes < 60) return '${diff.inMinutes}d';
      if (diff.inHours < 24) return '${diff.inHours}s';
      if (diff.inDays < 7) return '${diff.inDays}g';
      const months = [
        '', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
        'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
      ];
      return '${dt.day} ${months[dt.month]}';
    } catch (_) {
      return '';
    }
  }

  String get _initials {
    final parts = widget.item.displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.item.displayName.isNotEmpty
        ? widget.item.displayName
            .substring(0, widget.item.displayName.length.clamp(0, 2))
            .toUpperCase()
        : '?';
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'winning':   return AppColors.green;
      case 'risk':      return AppColors.red;
      case 'cancelled': return AppColors.textTertiary;
      default:          return AppColors.brand;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'winning':   return 'KAZANIYOR';
      case 'risk':      return 'KAYBETTİ';
      case 'pending':   return 'AKTİF';
      case 'cancelled': return 'İPTAL';
      default:          return s.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final d = _detail;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _detail?.status == 'winning'
                ? [const Color(0xFF1A241A), const Color(0xFF141814), const Color(0xFF0F100F)]
                : _detail?.status == 'risk'
                    ? [const Color(0xFF241A1A), const Color(0xFF181414), const Color(0xFF100F0F)]
                    : _detail?.status == 'pending'
                        ? [const Color(0xFF231E12), const Color(0xFF1A1710), const Color(0xFF12100C)]
                        : [const Color(0xFF1C1C22), const Color(0xFF161618), const Color(0xFF101012)],
            stops: const [0.0, 0.45, 1.0],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _detail?.status == 'winning'
                ? AppColors.green.withOpacity(0.22)
                : _detail?.status == 'risk'
                    ? AppColors.red.withOpacity(0.22)
                    : _detail?.status == 'pending'
                        ? const Color(0xFFFFBB00).withOpacity(0.20)
                        : Colors.white.withOpacity(0.07),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: _detail?.status == 'winning'
                  ? AppColors.green.withOpacity(0.10)
                  : _detail?.status == 'risk'
                      ? AppColors.red.withOpacity(0.10)
                      : _detail?.status == 'pending'
                          ? const Color(0xFFFFBB00).withOpacity(0.08)
                          : Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name + time ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.brand,
                            AppColors.brand.withOpacity(0.55),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${item.username}',
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _fmtDate(item.createdAt),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // ── Site badge ────────────────────────────────────────────────
            if (d != null && d.siteName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.brand.withOpacity(0.20), width: 0.5),
                  ),
                  child: Text(
                    d.siteName,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            // ── Coupon title ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  14,
                  (d != null && d.siteName.isNotEmpty) ? 6 : 12,
                  14,
                  0),
              child: Text(
                (d != null && d.title.isNotEmpty)
                    ? d.title
                    : 'Kupon #${item.couponId}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── Stats row ─────────────────────────────────────────────────
            if (d != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    _StatChip(label: 'Bahis', value: d.stake),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Oran', value: d.odds),
                    const SizedBox(width: 8),
                    _StatChip(label: 'Kazanç', value: d.potential),
                  ],
                ),
              ),

            // ── Selection progress ─────────────────────────────────────────
            if (d != null && d.selections.isNotEmpty)
              _SelectionProgress(selections: d.selections),

            // ── Status badge ──────────────────────────────────────────────
            if (d != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(d.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(d.status),
                        style: TextStyle(
                          color: _statusColor(d.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.textTertiary),
                  ],
                ),
              )
            else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selection progress bar ────────────────────────────────────────────────────

class _SelectionProgress extends StatelessWidget {
  final List<CouponSelection> selections;

  const _SelectionProgress({required this.selections});

  @override
  Widget build(BuildContext context) {
    final total = selections.length;
    final winning =
        selections.where((s) => s.status.toLowerCase() == 'winning').length;
    final pending =
        selections.where((s) => s.status.toLowerCase() == 'pending').length;
    final lost = total - winning - pending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$total seçim',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 4,
              child: Row(
                children: [
                  if (winning > 0)
                    Expanded(
                        flex: winning,
                        child: Container(color: AppColors.green)),
                  if (pending > 0)
                    Expanded(
                        flex: pending,
                        child: Container(
                            color: AppColors.textTertiary.withOpacity(0.3))),
                  if (lost > 0)
                    Expanded(
                        flex: lost,
                        child: Container(
                            color: AppColors.red.withOpacity(0.7))),
                  if (winning == 0 && pending == 0 && lost == 0)
                    Expanded(
                        child: Container(
                            color: AppColors.textTertiary.withOpacity(0.2))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (winning > 0) ...[
                const Text('✅', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '$winning',
                  style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
              ],
              if (pending > 0) ...[
                const Text('⏳', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '$pending',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
              ],
              if (lost > 0) ...[
                const Text('❌', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '$lost',
                  style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  final bool? hasFollowing;
  final VoidCallback? onSearchTap;

  const _EmptyBody({this.hasFollowing, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.07), width: 0.5),
              ),
              child: Icon(
                Icons.dynamic_feed_rounded,
                size: 34,
                color: AppColors.textTertiary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Henüz akış yok',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kullanıcı ara ve takip etmeye başla.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            if (onSearchTap != null)
              GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withOpacity(0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Kullanıcı Ara',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 36,
                color: AppColors.textTertiary.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'Yüklenemedi',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.brand.withOpacity(0.30), width: 0.5),
                ),
                child: const Text(
                  'Tekrar Dene',
                  style: TextStyle(
                      color: AppColors.brand,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
}
