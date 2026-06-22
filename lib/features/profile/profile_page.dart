import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/coupon.dart';
import '../../services/social_service.dart';
import 'feed_page.dart';
import 'shared_coupon_detail_page.dart';
import 'user_list_page.dart';
import 'user_search_page.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  /// Local coupons from the app — matched against sharedCoupon.couponId ↔ Coupon.sharedId
  final List<Coupon> localCoupons;
  /// Username of the currently logged-in user.
  /// When null or equal to [username], the page is in "own profile" mode.
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
  SocialUser?        _user;
  List<SharedCoupon> _sharedCoupons = [];
  bool    _loading = true;
  String? _error;

  // Follow state — only relevant when viewing another user's profile.
  bool? _isFollowing;
  bool  _followLoading = false;
  String? _currentUserId;

  bool get _isOwnProfile =>
      widget.currentUsername == null ||
      widget.currentUsername == widget.username;

  final _scrollController  = ScrollController();
  final _couponsHeaderKey  = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        SocialService.instance.getUser(widget.username),
        SocialService.instance.getSharedCoupons(widget.username),
      ]);
      if (!mounted) return;
      _user          = results[0] as SocialUser;
      _sharedCoupons = results[1] as List<SharedCoupon>;

      // Load follow state when viewing another user's profile.
      if (!_isOwnProfile) {
        try {
          final cu       = await SocialService.instance.getUser(widget.currentUsername!);
          final following = await SocialService.instance.getFollowing(widget.currentUsername!);
          if (!mounted) return;
          _currentUserId = cu.id;
          _isFollowing   = following.any((u) => u.username == widget.username);
        } catch (_) {
          _isFollowing = false;
        }
      }

      if (!mounted) return;
      setState(() { _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId == null || _user == null || _followLoading) return;
    final was = _isFollowing ?? false;
    // Optimistic update.
    setState(() { _followLoading = true; _isFollowing = !was; });
    try {
      if (was) {
        await SocialService.instance.unfollow(_currentUserId!, _user!.id);
      } else {
        await SocialService.instance.follow(_currentUserId!, _user!.id);
      }
      // Refresh counts.
      final updated = await SocialService.instance.getUser(widget.username);
      if (!mounted) return;
      setState(() { _user = updated; _followLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _isFollowing = was; _followLoading = false; });
    }
  }

  void _scrollToCoupons() {
    final ctx = _couponsHeaderKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: _loading
              ? const _LoadingBody()
              : _error != null
                  ? _ErrorBody(error: _error!, onRetry: _load)
                  : RefreshIndicator(
                      color: AppColors.brand,
                      backgroundColor: AppColors.card,
                      onRefresh: _load,
                      child: _ProfileBody(
                        user: _user!,
                        sharedCoupons: _sharedCoupons,
                        localCoupons: widget.localCoupons,
                        scrollController: _scrollController,
                        couponsHeaderKey: _couponsHeaderKey,
                        onScrollToCoupons: _scrollToCoupons,
                        isOwnProfile: _isOwnProfile,
                        isFollowing: _isFollowing,
                        followLoading: _followLoading,
                        onFollowTap: _toggleFollow,
                      ),
                    ),
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.brand, strokeWidth: 2),
      );
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 44, color: AppColors.textTertiary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Profil yüklenemedi',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Sunucuya bağlanılamıyor',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textTertiary.withOpacity(0.8),
                    fontSize: 13)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.brand.withOpacity(0.30), width: 0.5),
                ),
                child: const Text('Tekrar Dene',
                    style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile body ──────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final SocialUser user;
  final List<SharedCoupon> sharedCoupons;
  final List<Coupon> localCoupons;
  final ScrollController scrollController;
  final GlobalKey couponsHeaderKey;
  final VoidCallback onScrollToCoupons;
  final bool isOwnProfile;
  final bool? isFollowing;
  final bool followLoading;
  final VoidCallback onFollowTap;

  const _ProfileBody({
    required this.user,
    required this.sharedCoupons,
    required this.localCoupons,
    required this.scrollController,
    required this.couponsHeaderKey,
    required this.onScrollToCoupons,
    required this.isOwnProfile,
    this.isFollowing,
    this.followLoading = false,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Back button ───────────────────────────────────────────────────
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

        // ── Avatar + name ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(displayName: user.displayName),
                const SizedBox(height: 16),
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '@${user.username}',
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

        // ── Stats row (tappable) ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
            child: _StatsRow(
              followers:         user.followerCount,
              following:         user.followingCount,
              coupons:           sharedCoupons.length,
              username:          user.username,
              onScrollToCoupons: onScrollToCoupons,
            ),
          ),
        ),

        // ── Action buttons ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: isOwnProfile
                // Own profile: Arkadaş Ekle + Akış
                ? Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.person_add_rounded,
                          label: 'Arkadaş Ekle',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => UserSearchPage(currentUser: user),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.dynamic_feed_rounded,
                          label: 'Akış',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FeedPage(username: user.username),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                // Another user's profile: follow / unfollow button
                : _FollowButton(
                    isFollowing: isFollowing,
                    loading: followLoading,
                    onTap: onFollowTap,
                  ),
          ),
        ),

        // ── Shared coupons header ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Row(
              key: couponsHeaderKey,
              children: [
                const Text(
                  'AKTİF KUPONLAR',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                if (sharedCoupons.isNotEmpty)
                  Text(
                    '${sharedCoupons.length}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Shared coupons list ───────────────────────────────────────────
        if (sharedCoupons.isEmpty)
          const SliverToBoxAdapter(child: _EmptySharedCoupons())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final sc = sharedCoupons[i];
                  // Try to match against a local coupon by sharedId
                  final local = localCoupons
                      .where((c) => c.sharedId == sc.couponId)
                      .firstOrNull;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushNamed('/coupon/${sc.couponId}'),
                      child: local != null
                          ? _LocalCouponCard(coupon: local)
                          : _SharedCouponRow(coupon: sc),
                    ),
                  );
                },
                childCount: sharedCoupons.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppColors.brand),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.symmetric(vertical: 11),
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
                    color: following ? AppColors.textSecondary : AppColors.brand,
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
      width: 72,
      height: 72,
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
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
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
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FollowersPage(username: username),
              )),
            ),
          ),
          _VertDivider(),
          Expanded(
            child: _StatCell(
              value: following,
              label: 'Takip',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FollowingPage(username: username),
              )),
            ),
          ),
          _VertDivider(),
          Expanded(
            child: _StatCell(
              value: coupons,
              label: 'Kupon',
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


// ── Local coupon card (rich display when matched) ─────────────────────────────

class _LocalCouponCard extends StatelessWidget {
  final Coupon coupon;
  const _LocalCouponCard({required this.coupon});

  Color _statusColor(CouponStatus s) {
    switch (s) {
      case CouponStatus.winning:   return AppColors.green;
      case CouponStatus.risk:      return AppColors.red;
      case CouponStatus.pending:   return AppColors.textSecondary;
      case CouponStatus.cancelled: return AppColors.textTertiary;
    }
  }

  String _statusLabel(CouponStatus s) {
    switch (s) {
      case CouponStatus.winning:   return 'Kazanıyor';
      case CouponStatus.risk:      return 'Riskli';
      case CouponStatus.pending:   return 'Bekliyor';
      case CouponStatus.cancelled: return 'İptal';
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              child: Divider(height: 1, thickness: 0.5, color: Color(0x0DFFFFFF)),
            ),
            ...coupon.matche