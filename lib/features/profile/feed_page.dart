import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/social_service.dart';

class FeedPage extends StatefulWidget {
  final String username;

  const FeedPage({
    super.key,
    required this.username,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<FeedItem> _items = [];
  bool _loading = true;
  String? _error;
  // null = unknown, true = has followed users, false = following nobody
  bool? _hasFollowing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final items = await SocialService.instance.getFeed(widget.username);
      if (!mounted) return;
      debugPrint('[Feed] ${widget.username} → ${items.length} aktivite');

      bool? hasFollowing;
      if (items.isEmpty) {
        // Distinguish "no activity yet" from "not following anyone"
        try {
          final following =
              await SocialService.instance.getFollowing(widget.username);
          hasFollowing = following.isNotEmpty;
          debugPrint('[Feed] following count: ${following.length}');
        } catch (_) {
          hasFollowing = null;
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
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openDetail(FeedItem item) {
    Navigator.of(context).pushNamed('/coupon/${item.couponId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Akış',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  if (!_loading)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          size: 20, color: AppColors.textSecondary),
                      onPressed: _load,
                    ),
                ],
              ),
            ),

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brand, strokeWidth: 2))
                  : _error != null
                      ? _ErrorBody(error: _error!, onRetry: _load)
                      : _items.isEmpty
                          ? _EmptyBody(hasFollowing: _hasFollowing)
                          : RefreshIndicator(
                              color: AppColors.brand,
                              backgroundColor: AppColors.card,
                              onRefresh: _load,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 32),
                                itemCount: _items.length,
                                itemBuilder: (context, i) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: _FeedCard(
                                    item: _items[i],
                                    onTap: () => _openDetail(_items[i]),
                                  ),
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

// ── Feed card ─────────────────────────────────────────────────────────────────

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const _FeedCard({required this.item, required this.onTap});

  String get _label {
    switch (item.type) {
      case 'COUPON_WON':
        return '${item.displayName} kuponu kazandı 🎉';
      case 'COUPON_LOST':
        return '${item.displayName} kuponu kaybetti';
      default:
        return '${item.displayName} yeni kupon paylaştı';
    }
  }

  IconData get _icon {
    switch (item.type) {
      case 'COUPON_WON':  return Icons.emoji_events_rounded;
      case 'COUPON_LOST': return Icons.cancel_outlined;
      default:            return Icons.confirmation_number_outlined;
    }
  }

  Color get _iconColor {
    switch (item.type) {
      case 'COUPON_WON':  return AppColors.green;
      case 'COUPON_LOST': return AppColors.red;
      default:            return AppColors.brand;
    }
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}d önce';
      if (diff.inHours < 24)   return '${diff.inHours}s önce';
      const months = ['', 'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
                      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${dt.day} ${months[dt.month]}';
    } catch (_) { return raw; }
  }

  String get _initials {
    final parts = item.displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return item.displayName.isNotEmpty
        ? item.displayName
            .substring(0, item.displayName.length.clamp(0, 2))
            .toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
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
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Label + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _fmtDate(item.createdAt),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Type icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_icon, size: 15, color: _iconColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty + Error ─────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  final bool? hasFollowing;
  const _EmptyBody({this.hasFollowing});

  @override
  Widget build(BuildContext context) {
    final noFollowing = hasFollowing == false;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noFollowing
                ? Icons.person_add_alt_1_rounded
                : Icons.dynamic_feed_rounded,
            size: 40,
            color: AppColors.textTertiary.withOpacity(0.35),
          ),
          const SizedBox(height: 12),
          Text(
            noFollowing
                ? 'Henüz kimseyi takip etmiyorsun'
                : 'Henüz aktivite yok',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noFollowing
                ? 'Arkadaş eklemek için profil ekranına git'
                : 'Takip ettiğin kullanıcıların paylaşımları\nburada görünecek',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTertiary.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

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
                size: 36, color: AppColors.textTertiary.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('Yüklenemedi',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.brand.withOpacity(0.30), width: 0.5),
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
