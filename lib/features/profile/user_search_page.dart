import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/social_service.dart';
import 'profile_page.dart';

class UserSearchPage extends StatefulWidget {
  /// The currently logged-in user — needed to call follow/unfollow.
  final SocialUser currentUser;

  const UserSearchPage({super.key, required this.currentUser});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  List<SocialUser> _results = [];
  bool _loading = false;
  String? _error;

  // Track local follow state: userId → isFollowing
  final Map<String, bool> _followState = {};

  @override
  void initState() {
    super.initState();
    _loadInitialFollowState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  /// Pre-loads the current user's following list so buttons show the correct
  /// state immediately when search results appear.
  Future<void> _loadInitialFollowState() async {
    try {
      final following = await SocialService.instance
          .getFollowing(widget.currentUser.username);
      if (!mounted) return;
      setState(() {
        for (final u in following) {
          _followState[u.id] = true;
        }
      });
    } catch (_) {
      // Non-critical — buttons default to "Takip Et" if this fails.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _results = []; _loading = false; _error = null; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await SocialService.instance.searchUsers(q);
      if (!mounted) return;
      debugPrint('[UserSearch] "$q" → ${res.length} sonuç');
      setState(() { _results = res; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Arama başarısız'; _loading = false; });
    }
  }

  Future<void> _toggleFollow(SocialUser target) async {
    final isFollowing = _followState[target.id] ?? false;
    // Optimistic update
    setState(() => _followState[target.id] = !isFollowing);
    if (isFollowing) {
      await SocialService.instance
          .unfollow(widget.currentUser.id, target.id);
      debugPrint('[UserSearch] takipten çıkıldı: @${target.username}');
    } else {
      await SocialService.instance
          .follow(widget.currentUser.id, target.id);
      debugPrint('[UserSearch] takip edildi: @${target.username}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kullanıcı Ara',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search field ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.08), width: 0.5),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  focusNode: _focusNode,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı adı veya isim',
                    hintStyle: TextStyle(
                        color: AppColors.textTertiary.withOpacity(0.7),
                        fontSize: 15),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textTertiary, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Results ──────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brand, strokeWidth: 2))
                  : _error != null
                      ? _ErrorState(message: _error!)
                      : _controller.text.trim().isEmpty
                          ? const _HintState()
                          : _results.isEmpty
                              ? const _EmptyState()
                              : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _results.length,
                              itemBuilder: (context, i) {
                                final u = _results[i];
                                final isSelf =
                                    u.id == widget.currentUser.id;
                                final isFollowing =
                                    _followState[u.id] ?? false;
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: _UserRow(
                                    user: u,
                                    isSelf: isSelf,
                                    isFollowing: isFollowing,
                                    onFollowTap: isSelf
                                        ? null
                                        : () => _toggleFollow(u),
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProfilePage(
                                          username: u.username,
                                          currentUsername:
                                              widget.currentUser.username,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
              ],
            ),    // Column
          ),      // ConstrainedBox
        ),        // Center
      ),          // SafeArea
    );
  }
}

// ── User row ──────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  final SocialUser user;
  final bool isSelf;
  final bool isFollowing;
  final VoidCallback? onFollowTap;
  final VoidCallback onTap;

  const _UserRow({
    required this.user,
    required this.isSelf,
    required this.isFollowing,
    required this.onFollowTap,
    required this.onTap,
  });

  String get _initials {
    final parts = user.displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return user.displayName.isNotEmpty
        ? user.displayName
            .substring(0, user.displayName.length.clamp(0, 2))
            .toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brand,
                    AppColors.brand.withOpacity(0.55)
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Follow button
            if (!isSelf && onFollowTap != null)
              GestureDetector(
                onTap: onFollowTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isFollowing
                        ? Colors.white.withOpacity(0.06)
                        : AppColors.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFollowing
                          ? Colors.white.withOpacity(0.12)
                          : AppColors.brand.withOpacity(0.35),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Takiptesin' : 'Takip Et',
                    style: TextStyle(
                      color: isFollowing
                          ? AppColors.textSecondary
                          : AppColors.brand,
                      fontSize: 12,
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

// ── Hint / Empty / Error states ───────────────────────────────────────────────

class _HintState extends StatelessWidget {
  const _HintState();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'Kullanıcı adı veya isim ara',
          style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'Kullanıcı bulunamadı',
          style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          message,
          style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
      );
}
