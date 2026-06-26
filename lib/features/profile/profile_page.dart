import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/coupon.dart';
import '../../services/social_service.dart';
import '../home/match_row.dart';
import 'feed_page.dart';
import 'user_list_page.dart';
import 'user_search_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final List<Coupon> localCoupons;
  final String? currentUsername;

  const ProfilePage({
    super.key,
    required this.username,
    this.localCoupons = const [],
    this.currentUsername,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  SocialUser? _user;
  List<SharedCoupon> _sharedCoupons = [];
  bool _loading = true;
  String? _error;

  bool? _isFollowing;
  bool _followLoading = false;
  String? _currentUserId;

  bool get _isOwnProfile =>
      widget.currentUsername == null ||
      widget.currentUsername == widget.username;

  final _scrollController = ScrollController();
  final _couponsHeaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        SocialService.instance.getUser(widget.username),
        SocialService.instance.getSharedCoupons(widget.username),
      ]);

      _user = results[0] as SocialUser;
      _sharedCoupons = results[1] as List<SharedCoupon>;

      if (!_isOwnProfile) {
        try {
          final cu =
              await SocialService.instance.getUser(widget.currentUsername!);
          final following =
              await SocialService.instance.getFollowing(widget.currentUsername!);

          _currentUserId = cu.id;
          _isFollowing =
              following.any((u) => u.username == widget.username);
        } catch (_) {
          _isFollowing = false;
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null || _user == null || _followLoading) return;

    final was = _isFollowing ?? false;

    setState(() {
      _followLoading = true;
      _isFollowing = !was;
      // Optimistic count — corrected by getUser() once API responds
      if (_user != null) {
        final u = _user!;
        _user = SocialUser(
          id: u.id,
          username: u.username,
          displayName: u.displayName,
          avatar: u.avatar,
          createdAt: u.createdAt,
          followerCount: (u.followerCount + (was ? -1 : 1)).clamp(0, 999999),
          followingCount: u.followingCount,
        );
      }
    });

    try {
      if (was) {
        await SocialService.instance.unfollow(_currentUserId!, _user!.id);
      } else {
        await SocialService.instance.follow(_currentUserId!, _user!.id);
      }

      final updated =
          await SocialService.instance.getUser(widget.username);

      if (!mounted) return;
      setState(() {
        _user = updated;
        _followLoading = false;
      });
    } catch (_) {
      setState(() {
        _isFollowing = was;
        _followLoading = false;
      });
    }
  }

  void _scrollToCoupons() {
    final ctx = _couponsHeaderKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brand, strokeWidth: 2))
                : _error != null
                    ? _ErrorState(message: _error!, onRetry: _load)
                    : CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          // ── Top bar ──────────────────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Avatar + display name + username ─────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _Avatar(
                                      displayName:
                                          _user?.displayName ?? widget.username),
                                  const SizedBox(height: 14),
                                  Text(
                                    _user?.displayName ?? widget.username,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${widget.username}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Stats: followers / following / coupons ───────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                              child: _StatsRow(
                                followers: _user?.followerCount ?? 0,
                                following: _user?.followingCount ?? 0,
                                coupons: _sharedCoupons.length,
                                username: widget.username,
                                onScrollToCoupons: _scrollToCoupons,
                              ),
                            ),
                          ),

                          // ── Action buttons ───────────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                              child: _isOwnProfile
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: _ActionButton(
                                            label: 'Kullanıcı Ara',
                                            icon: Icons.person_search_rounded,
                                            onTap: () {
                                              if (_user == null) return;
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => UserSearchPage(
                                                      currentUser: _user!),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: _ActionButton(
                                            label: 'Akış',
                                            icon: Icons.dynamic_feed_rounded,
                                            filled: true,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FeedPage(
                                                    username: widget.username,
                                                    showBack: true),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : _FollowButton(
                                      isFollowing: _isFollowing,
                                      loading: _followLoading,
                                      onTap: _toggleFollow,
                                    ),
                            ),
                          ),

                          // ── Section header ───────────────────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              key: _couponsHeaderKey,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 30, 20, 14),
                              child: Row(
                                children: [
                                  const Text(
                                    'AKTİF KUPONLAR',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_sharedCoupons.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.brand.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_sharedCoupons.length}',
                                        style: const TextStyle(
                                          color: AppColors.brand,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // ── Coupon list or empty state ───────────────────────
                          if (_sharedCoupons.isEmpty)
                            const SliverToBoxAdapter(
                                child: _EmptySharedCoupons())
                          else
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 40),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final sc = _sharedCoupons[i];
                                    final local = widget.localCoupons
                                        .where((c) =>
                                            c.sharedId == sc.couponId)
                                        .firstOrNull;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: local != null
                                          ? _LocalCouponCard(coupon: local)
                                          : _SharedCouponRow(coupon: sc),
                                    );
                                  },
                                  childCount: _sharedCoupons.length,
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

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.textTertiary, size: 40),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.brand.withOpacity(0.35), width: 0.5),
                ),
                child: const Text('Tekrar Dene',
                    style: TextStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action button (own-profile) ───────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.brand.withOpacity(0.15)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? AppColors.brand.withOpacity(0.35)
                : Colors.white.withOpacity(0.10),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: filled ? AppColors.brand : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: filled ? AppColors.brand : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Follow button (other user's profile) ─────────────────────────────────────

class _FollowButton extends StatelessWidget {
  final bool? isFollowing;
  final bool loading;
  final VoidCallback onTap;

  const _FollowButton({
    required this.isFollowing,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final following = isFollowing ?? false;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: following
              ? Colors.white.withOpacity(0.06)
              : AppColors.brand.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: following
                ? Colors.white.withOpacity(0.10)
                : AppColors.brand.withOpacity(0.35),
            width: 0.5,
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: AppColors.brand),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    following
                        ? Icons.person_remove_rounded
                        : Icons.person_add_rounded,
                    size: 15,
                    color: following
                        ? AppColors.textSecondary
                        : AppColors.brand,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    following ? 'Takibi Bırak' : 'Takip Et',
                    style: TextStyle(
                      color: following
                          ? AppColors.textSecondary
                          : AppColors.brand,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String displayName;
  const _Avatar({required this.displayName});

  String get _initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return displayName.isNotEmpty
        ? displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brand.withOpacity(0.60)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int followers;
  final int following;
  final int coupons;
  final String username;
  final VoidCallback onScrollToCoupons;

  const _StatsRow({
    required this.followers,
    required this.following,
    required this.coupons,
    required this.username,
    required this.onScrollToCoupons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: followers,
              label: 'Takipçi',
            ),
          ),
          _VertDivider(),
          Expanded(
            child: _StatCell(
              value: following,
              label: 'Takip',
            ),
          ),
          _VertDivider(),
          Expanded(
            child: _StatCell(
              value: coupons,
              label: 'Kupon',
              onTap: onScrollToCoupons,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _StatCell({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: onTap != null
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 0.5,
        height: 36,
        color: Colors.white.withOpacity(0.08),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptySharedCoupons extends StatelessWidget {
  const _EmptySharedCoupons();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🏟️', style: TextStyle(fontSize: 32)),
          SizedBox(height: 12),
          Text(
            'Henüz paylaşılan kupon yok.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Kupon paylaşıldığında burada görünür.',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Shared coupon card (fetches CouponDetail for rich display) ────────────────

class _SharedCouponRow extends StatefulWidget {
  final SharedCoupon coupon;
  const _SharedCouponRow({required this.coupon});

  @override
  State<_SharedCouponRow> createState() => _SharedCouponRowState();
}

class _SharedCouponRowState extends State<_SharedCouponRow> {
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
          .getCouponDetail(widget.coupon.couponId);
      if (mounted) setState(() { _detail = d; _fetching = false; });
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'winning':   return AppColors.green;
      case 'risk':      return AppColors.red;
      case 'cancelled': return AppColors.textTertiary;
      default:          return AppColors.textSecondary;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'winning':   return 'Kazanıyor';
      case 'risk':      return 'Riskli';
      case 'pending':   return 'Bekliyor';
      case 'cancelled': return 'İptal';
      default:          return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                color: AppColors.brand, strokeWidth: 1.5),
          ),
        ),
      );
    }

    final d = _detail;
    if (d == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.brand.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.brand, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kupon #${widget.coupon.couponId}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    d.title.isNotEmpty ? d.title : 'Kupon #${d.couponId}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(d.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(d.status),
                    style: TextStyle(
                      color: _statusColor(d.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                if (d.siteName.isNotEmpty) ...[
                  const Icon(Icons.language_rounded,
                      size: 11, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(d.siteName,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
                  const SizedBox(width: 10),
                ],
                if (d.selections.isNotEmpty) ...[
                  const Icon(Icons.format_list_numbered_rounded,
                      size: 11, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text('${d.selections.length} seçim',
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                _MiniStat(label: 'Bahis',    value: d.stake),
                const SizedBox(width: 16),
                _MiniStat(label: 'Oran',     value: d.odds),
                const SizedBox(width: 16),
                _MiniStat(label: 'Beklenti', value: d.potential),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Local coupon card (rich display when matched) ─────────────────────────────

class _LocalCouponCard extends StatelessWidget {
  final Coupon coupon;
  const _LocalCouponCard({required this.coupon});

  Color _statusColor(CouponStatus s) {
    switch (s) {
      case CouponStatus.winning:   return AppColors.green;
      case CouponStatus.risk:      return AppColors.red;
      case CouponStatus.pending:   return AppColors.textSecondary;
      case CouponStatus.cancelled:
      case CouponStatus.void_: return AppColors.textTertiary;
    }
  }

  String _statusLabel(CouponStatus s) {
    switch (s) {
      case CouponStatus.winning:   return 'Kazanıyor';
      case CouponStatus.risk:      return 'Riskli';
      case CouponStatus.pending:   return 'Bekliyor';
      case CouponStatus.cancelled:
      case CouponStatus.void_: return 'İptal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final oddsMatch = RegExp(r'×([\d.,]+)').firstMatch(coupon.meta);
    final oddsDisplay = oddsMatch != null ? '×${oddsMatch.group(1)}' : '—';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(coupon.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(coupon.status),
                    style: TextStyle(
                      color: _statusColor(coupon.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              coupon.meta,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                _MiniStat(label: 'Bahis',    value: coupon.stake),
                const SizedBox(width: 16),
                _MiniStat(label: 'Oran',     value: oddsDisplay),
                const SizedBox(width: 16),
                _MiniStat(label: 'Beklenti', value: coupon.potential),
              ],
            ),
          ),
          if (coupon.matches.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0x0DFFFFFF),
              ),
            ),
            ...coupon.matches.map((m) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: MatchRow(match: m),
                )).toList(),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// ── Mini stat cell inside coupon card ─────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
