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

  const FeedPage({super.key, required this.username, this.showBack = false});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

enum _FeedFilterTab { all, active, winning, losing }

class _FeedPageState extends State<FeedPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  List<FeedItem> _items = [];
  final Map<String, CouponDetail?> _details = {};
  bool _loading = true;
  String? _error;
  bool? _hasFollowing;
  SocialUser? _currentUser;
  _FeedFilterTab _activeTab = _FeedFilterTab.active;

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
          final following = await SocialService.instance.getFollowing(
            widget.username,
          );
          hasFollowing = following.isNotEmpty;

          if (following.isNotEmpty) {
            final built = <FeedItem>[];
            for (final u in following) {
              try {
                final coupons = await SocialService.instance.getSharedCoupons(
                  u.username,
                );
                for (final c in coupons) {
                  built.add(
                    FeedItem(
                      type: 'SHARED_COUPON',
                      username: u.username,
                      displayName: u.displayName,
                      couponId: c.couponId,
                      createdAt: c.createdAt,
                    ),
                  );
                }
              } catch (_) {}
            }
            built.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            items = built;
          }
        } catch (_) {
          hasFollowing = null;
        }
      } else {
        hasFollowing = true;
      }

      // Kullanıcının kendi public kuponlarını her zaman feed'e ekle
      if (_currentUser != null) {
        try {
          final own = await SocialService.instance.getSharedCoupons(
            widget.username,
          );
          if (own.isNotEmpty) {
            final u = _currentUser!;
            final ownIds = own.map((c) => c.couponId).toSet();
            // Zaten feed'de varsa tekrar ekleme
            items.removeWhere(
              (i) => ownIds.contains(i.couponId) && i.username == u.username,
            );
            final ownItems = own
                .map(
                  (c) => FeedItem(
                    type: 'SHARED_COUPON',
                    username: u.username,
                    displayName: u.displayName,
                    couponId: c.couponId,
                    createdAt: c.createdAt,
                  ),
                )
                .toList();
            items = [...ownItems, ...items];
            items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
        } catch (_) {}
      }

      // Sekmelerde (Aktif/Kazanan/Kaybeden) filtreleyebilmek için her kuponun
      // durumunu baştan toplu çek.
      final details = <String, CouponDetail?>{};
      await Future.wait(
        items.map((it) async {
          try {
            details[it.couponId] = await SocialService.instance.getCouponDetail(
              it.couponId,
            );
          } catch (_) {
            details[it.couponId] = null;
          }
        }),
      );

      if (!mounted) return;
      setState(() {
        _items = items;
        _details
          ..clear()
          ..addAll(details);
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

  String _statusOf(FeedItem item) =>
      (_details[item.couponId]?.status ?? 'pending').toLowerCase();

  List<FeedItem> get _filteredItems {
    switch (_activeTab) {
      case _FeedFilterTab.all:
        return _items;
      case _FeedFilterTab.active:
        return _items.where((i) => _statusOf(i) == 'pending').toList();
      case _FeedFilterTab.winning:
        return _items.where((i) => _statusOf(i) == 'winning').toList();
      case _FeedFilterTab.losing:
        return _items.where((i) => _statusOf(i) == 'risk').toList();
    }
  }

  int _tabCount(_FeedFilterTab tab) {
    switch (tab) {
      case _FeedFilterTab.all:
        return _items.length;
      case _FeedFilterTab.active:
        return _items.where((i) => _statusOf(i) == 'pending').length;
      case _FeedFilterTab.winning:
        return _items.where((i) => _statusOf(i) == 'winning').length;
      case _FeedFilterTab.losing:
        return _items.where((i) => _statusOf(i) == 'risk').length;
    }
  }

  String _tabLabel(_FeedFilterTab tab) {
    switch (tab) {
      case _FeedFilterTab.all:
        return 'Tümü';
      case _FeedFilterTab.active:
        return 'Aktif';
      case _FeedFilterTab.winning:
        return 'Kazanan';
      case _FeedFilterTab.losing:
        return 'Kaybeden';
    }
  }

  String _emptyTabMessage(_FeedFilterTab tab) {
    switch (tab) {
      case _FeedFilterTab.all:
        return 'Henüz akış yok';
      case _FeedFilterTab.active:
        return 'Aktif paylaşım yok';
      case _FeedFilterTab.winning:
        return 'Kazanan paylaşım yok';
      case _FeedFilterTab.losing:
        return 'Kaybeden paylaşım yok';
    }
  }

  void _openSearch() {
    if (_currentUser == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserSearchPage(currentUser: _currentUser!),
      ),
    );
  }

  void _openProfile(String username) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfilePage(username: username, currentUsername: widget.username),
      ),
    );
  }

  void _openDetail(FeedItem item) {
    final sc = SharedCoupon(
      id: item.couponId,
      couponId: item.couponId,
      isPublic: true,
      createdAt: item.createdAt,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharedCouponDetailPage(sharedCoupon: sc),
      ),
    );
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
                    widget.showBack ? 4 : 16,
                    14,
                    16,
                    0,
                  ),
                  child: Row(
                    children: [
                      if (widget.showBack)
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      const Spacer(),
                      if (!_loading)
                        GestureDetector(
                          onTap: _load,
                          child: Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Large title ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 0.5),
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

                // ── Filter tabs ──────────────────────────────────────────────
                if (!_loading && _error == null && _items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _FeedFilterTabBar(
                      activeTab: _activeTab,
                      tabLabel: _tabLabel,
                      tabCount: _tabCount,
                      onTabSelected: (tab) => setState(() => _activeTab = tab),
                    ),
                  ),

                // ── Body ─────────────────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brand,
                            strokeWidth: 2,
                          ),
                        )
                      : _error != null
                      ? _ErrorBody(error: _error!, onRetry: _load)
                      : _items.isEmpty
                      ? _EmptyBody(
                          hasFollowing: _hasFollowing,
                          onSearchTap: _currentUser != null
                              ? _openSearch
                              : null,
                        )
                      : _filteredItems.isEmpty
                      ? _EmptyTabBody(message: _emptyTabMessage(_activeTab))
                      : RefreshIndicator(
                          color: AppColors.brand,
                          backgroundColor: AppColors.card,
                          onRefresh: _load,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, i) {
                              final item = _filteredItems[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _FeedCard(
                                  item: item,
                                  detail: _details[item.couponId],
                                  onTap: () => _openDetail(item),
                                  onProfileTap: () =>
                                      _openProfile(item.username),
                                ),
                              );
                            },
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

// ── Feed card (CouponDetail prefetched by parent for tab filtering) ───────────

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  final CouponDetail? detail;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;

  const _FeedCard({
    required this.item,
    required this.detail,
    required this.onTap,
    required this.onProfileTap,
  });

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
        '',
        'Oca',
        'Şub',
        'Mar',
        'Nis',
        'May',
        'Haz',
        'Tem',
        'Ağu',
        'Eyl',
        'Eki',
        'Kas',
        'Ara',
      ];
      return '${dt.day} ${months[dt.month]}';
    } catch (_) {
      return '';
    }
  }

  String get _initials {
    final parts = item.displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return item.displayName.isNotEmpty
        ? item.displayName
              .substring(0, item.displayName.length.clamp(0, 2))
              .toUpperCase()
        : '?';
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'winning':
        return AppColors.green;
      case 'risk':
        return AppColors.red;
      case 'cancelled':
        return AppColors.textTertiary;
      default:
        return AppColors.brand;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'winning':
        return 'KAZANIYOR';
      case 'risk':
        return 'KAYBETTİ';
      case 'pending':
        return 'AKTİF';
      case 'cancelled':
        return 'İPTAL';
      default:
        return s.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = detail;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: d?.status == 'winning'
              ? const Border(
                  left: BorderSide(color: Color(0xFF16A34A), width: 3),
                )
              : d?.status == 'risk'
              ? const Border(
                  left: BorderSide(color: Color(0xFFDC2626), width: 3),
                )
              : Border.all(color: AppColors.border, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x142D4A6E),
              blurRadius: 20,
              offset: Offset(0, 4),
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
                    onTap: onProfileTap,
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
                      onTap: onProfileTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${item.username}',
                            style: TextStyle(
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
                    style: TextStyle(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.brand.withOpacity(0.20),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    d.siteName,
                    style: TextStyle(
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
                0,
              ),
              child: Text(
                (d != null && d.title.isNotEmpty)
                    ? d.title
                    : 'Kupon #${item.couponId}',
                style: TextStyle(
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
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
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
          color: AppColors.border,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
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
    final winning = selections
        .where((s) => s.status.toLowerCase() == 'winning')
        .length;
    final pending = selections
        .where((s) => s.status.toLowerCase() == 'pending')
        .length;
    final lost = total - winning - pending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$total seçim',
            style: TextStyle(
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
                      child: Container(color: AppColors.green),
                    ),
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: Container(
                        color: AppColors.textTertiary.withOpacity(0.3),
                      ),
                    ),
                  if (lost > 0)
                    Expanded(
                      flex: lost,
                      child: Container(color: AppColors.red.withOpacity(0.7)),
                    ),
                  if (winning == 0 && pending == 0 && lost == 0)
                    Expanded(
                      child: Container(
                        color: AppColors.textTertiary.withOpacity(0.2),
                      ),
                    ),
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
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (pending > 0) ...[
                const Text('⏳', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '$pending',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (lost > 0) ...[
                const Text('❌', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 3),
                Text(
                  '$lost',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
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
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Icon(
                Icons.dynamic_feed_rounded,
                size: 34,
                color: AppColors.textTertiary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz akış yok',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kullanıcı ara ve takip etmeye başla.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),
            if (onSearchTap != null)
              GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
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
        Icon(
          Icons.cloud_off_rounded,
          size: 36,
          color: AppColors.textTertiary.withOpacity(0.4),
        ),
        const SizedBox(height: 12),
        Text(
          'Yüklenemedi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.brand.withOpacity(0.30),
                width: 0.5,
              ),
            ),
            child: Text(
              'Tekrar Dene',
              style: TextStyle(
                color: AppColors.brand,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Empty tab state (items exist, but none match the active filter) ──────────

class _EmptyTabBody extends StatelessWidget {
  final String message;
  const _EmptyTabBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 34,
              color: AppColors.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter tab bar (Aktif / Kazanan / Kaybeden / Tümü) ────────────────────────

class _FeedFilterTabBar extends StatelessWidget {
  final _FeedFilterTab activeTab;
  final String Function(_FeedFilterTab) tabLabel;
  final int Function(_FeedFilterTab) tabCount;
  final ValueChanged<_FeedFilterTab> onTabSelected;

  const _FeedFilterTabBar({
    required this.activeTab,
    required this.tabLabel,
    required this.tabCount,
    required this.onTabSelected,
  });

  Widget _pill(_FeedFilterTab tab) {
    final isActive = tab == activeTab;
    final count = tabCount(tab);

    return GestureDetector(
      onTap: () => onTabSelected(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brand : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.brand : AppColors.border,
            width: 0.6,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.brand.withOpacity(0.20),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tabLabel(tab),
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.20)
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: 5);
    return Row(
      children: [
        Expanded(child: _pill(_FeedFilterTab.active)),
        gap,
        Expanded(child: _pill(_FeedFilterTab.winning)),
        gap,
        Expanded(child: _pill(_FeedFilterTab.losing)),
        gap,
        Expanded(child: _pill(_FeedFilterTab.all)),
      ],
    );
  }
}
