import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/coupon_share.dart';
import '../../services/social_service.dart';
import '../../services/auth_service.dart';
import '../../services/coupon_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/coupon.dart';
import '../../services/match_search_service.dart';
import 'dart:async';
import '../add_coupon/add_coupon_sheet.dart';
import '../coupon/coupon_detail_page.dart';
import '../ayarlar/ayarlar_page.dart';
import '../profile/feed_page.dart';
import '../istatistik/istatistik_page.dart';
import '../shared_coupon/shared_coupon_preview_page.dart';
import 'bottom_nav.dart';
import 'notification_bell.dart';
import '../../services/notification_service.dart';
import 'coupon_card.dart';
import 'section_header.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum _FilterTab { all, active, winning, losing }

class _CouponEntry {
  Coupon coupon;
  bool isFavorite;
  _CouponEntry({required this.coupon, this.isFavorite = false});
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class MatchlyHomePage extends StatefulWidget {
  final String? pendingCouponId;
  const MatchlyHomePage({super.key, this.pendingCouponId});

  @override
  State<MatchlyHomePage> createState() => _MatchlyHomePageState();
}

class _MatchlyHomePageState extends State<MatchlyHomePage> {

  // ── active coupons ─────────────────────────────────────────────────────────

  final List<_CouponEntry> _entries = [];

  // ── history coupons ────────────────────────────────────────────────────────

  final List<_CouponEntry> _historyEntries = [];

  // ── UI state ───────────────────────────────────────────────────────────────

  _FilterTab _activeTab   = _FilterTab.active;
  int        _navIndex    = 0;

  // ── supabase realtime ─────────────────────────────────────────────────────

  void _subscribeToSupabaseCoupons() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _couponChannel = Supabase.instance.client
        .channel('coupons:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'coupons',
          callback: (payload) async {
            final updated = payload.newRecord;
            final couponId = updated['id'];
            final newStatus = updated['status'] as String? ?? 'pending';

            // coupon_matches de güncelle
            final matchRows = await Supabase.instance.client
                .from('coupon_matches')
                .select()
                .eq('coupon_id', couponId)
                .order('sort_order');

            if (!mounted) return;
            setState(() {
              for (final entry in _entries) {
                // ID ile eşleştir
                if (entry.coupon.id.toString() == couponId.toString()) {
                  final status = CouponStatus.values.firstWhere(
                    (s) => s.name == newStatus,
                    orElse: () => CouponStatus.pending,
                  );
                  final matches = (matchRows as List).map<MatchItem>((m) {
                    final mStatus = CouponStatus.values.firstWhere(
                      (s) => s.name == ((m['status'] ?? 'pending') == 'void' ? 'void_' : (m['status'] ?? 'pending')),
                      orElse: () => CouponStatus.pending,
                    );
                    return MatchItem(
                      teams: m['teams'] ?? '',
                      selection: m['selection'] ?? '',
                      score: m['score'] ?? '',
                      minute: m['minute'] ?? '',
                      status: mStatus,
                    );
                  }).toList();
                  entry.coupon = entry.coupon.copyWithMatches(matches).copyWith(status: status);
                }
              }
            });
          },
        )
        .subscribe();

    // coupon_matches realtime
    _matchChannel = Supabase.instance.client
        .channel('coupon_matches:\$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'coupon_matches',
          callback: (payload) async {
            final updated = payload.newRecord;
            final couponId = updated['coupon_id'];
            if (!mounted) return;

            final matchRows = await Supabase.instance.client
                .from('coupon_matches')
                .select()
                .eq('coupon_id', couponId)
                .order('sort_order');

            setState(() {
              for (final entry in _entries) {
                if (entry.coupon.id.toString() == couponId.toString()) {
                  final matches = (matchRows as List).map<MatchItem>((m) {
                    final mStatus = CouponStatus.values.firstWhere(
                      (s) => s.name == ((m['status'] ?? 'pending') == 'void' ? 'void_' : (m['status'] ?? 'pending')),
                      orElse: () => CouponStatus.pending,
                    );
                    return MatchItem(
                      teams: m['teams'] ?? '',
                      selection: m['selection'] ?? '',
                      score: m['score'] ?? '',
                      minute: m['minute'] ?? '',
                      status: mStatus,
                    );
                  }).toList();
                  entry.coupon = entry.coupon.copyWithMatches(matches);
                }
              }
            });
          },
        )
        .subscribe();
  }

  // ── live scores ────────────────────────────────────────────────────────────
  Timer? _liveTimer;
  Map<String, LiveMatch> _liveMatches = {};
  RealtimeChannel? _couponChannel;
  RealtimeChannel? _matchChannel;

  String _searchQuery  = '';
  String _siteFilter   = 'Tümü';
  String _leagueFilter = 'Tümü';

  AppUser? _user;

  String get _currentUsername => _user?.username ?? 'ozhan';

  late TextEditingController _searchController;

  static const _siteOptions   = ['Tümü', 'Bilyoner', 'Misli', 'Nesine', 'Betano'];
  static const _leagueOptions = ['Tümü', 'Dünya Kupası', 'Şampiyonlar Ligi', 'Premier Lig', 'Diğer'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadUser();
    _startLiveScoreTimer();
    _subscribeToSupabaseCoupons();
    if (widget.pendingCouponId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCouponById(widget.pendingCouponId!);
      });
    }
  }

  @override
  void didUpdateWidget(MatchlyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingCouponId != null &&
        widget.pendingCouponId != oldWidget.pendingCouponId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCouponById(widget.pendingCouponId!);
      });
    }
  }

  void _openCouponById(String couponId) {
    final entry = _entries.firstWhere(
      (e) => e.coupon.id.toString() == couponId,
      orElse: () => _historyEntries.firstWhere(
        (e) => e.coupon.id.toString() == couponId,
        orElse: () => _entries.isNotEmpty ? _entries.first : throw Exception('not found'),
      ),
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CouponDetailPage(
        coupon: entry.coupon,
        resolved: entry.coupon.status != CouponStatus.pending,
        allCoupons: _entries.map((e) => e.coupon).toList(),
      ),
    ));
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.getCurrentUser();
    final coupons = await CouponStorageService.instance.loadCoupons();

    if (!mounted) return;

    setState(() {
      _user = user;
      _entries
        ..clear()
        ..addAll(coupons.map((c) => _CouponEntry(coupon: c)));
    });

    // Her açılışta social DB'ye kullanıcıyı kaydet (yeni kayıt veya eksik kayıt için)
    if (user != null) {
      try {
        await SocialService.instance.ensureUser(user.username, user.displayName);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _couponChannel?.unsubscribe();
    _matchChannel?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  // ── live scores ────────────────────────────────────────────────────────────

  void _startLiveScoreTimer() {
    _fetchLiveScores();
    _liveTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchLiveScores());
  }

  Future<void> _fetchLiveScores() async {
    try {
      final matches = await MatchSearchService.instance.getLiveMatches();
      if (!mounted) return;
      final map = <String, LiveMatch>{};
      for (final m in matches) {
        final key = '${m.home} – ${m.away}';
        map[key] = m;
        // Ters sıra da ekle
        map['${m.away} – ${m.home}'] = m;
      }
      setState(() => _liveMatches = map);
    } catch (_) {}
  }

  List<MatchItem> _enrichMatches(List<MatchItem> matches) {
    return matches.map((m) {
      final live = _liveMatches[m.teams];
      if (live == null) return m;
      return MatchItem(
        teams: m.teams,
        selection: m.selection,
        score: live.scoreText,
        minute: live.isLive ? live.minute : m.minute,
        status: m.status,
      );
    }).toList();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static String _parseSite(Coupon c) => c.meta.split('·').first.trim();

  static String _detectLeague(Coupon c) {
    final t = '${c.title} ${c.meta}'.toLowerCase();
    if (t.contains('dünya kupası')) return 'Dünya Kupası';
    if (t.contains('şampiyonlar') || t.contains('champions')) return 'Şampiyonlar Ligi';
    if (t.contains('premier')) return 'Premier Lig';
    return 'Diğer';
  }

  // ── computed ───────────────────────────────────────────────────────────────

  String _tabLabel(_FilterTab tab) {
    switch (tab) {
      case _FilterTab.all:     return 'Tümü';
      case _FilterTab.active:  return 'Aktif';
      case _FilterTab.winning: return 'Kazanan';
      case _FilterTab.losing:  return 'Kaybeden';
    }
  }

  /// Entries after search + site + league filters (before tab filter).
  List<_CouponEntry> get _preFiltered {
    var list = _entries.toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        final c = e.coupon;
        if (c.title.toLowerCase().contains(q)) return true;
        if (_parseSite(c).toLowerCase().contains(q)) return true;
        return c.matches.any((m) =>
            m.teams.toLowerCase().contains(q) ||
            m.selection.toLowerCase().contains(q));
      }).toList();
    }

    if (_siteFilter != 'Tümü') {
      list = list.where((e) => _parseSite(e.coupon) == _siteFilter).toList();
    }

    if (_leagueFilter != 'Tümü') {
      list = list.where((e) => _detectLeague(e.coupon) == _leagueFilter).toList();
    }

    return list;
  }

  int _tabCount(_FilterTab tab) {
    final pre = _preFiltered;
    switch (tab) {
      case _FilterTab.all:     return pre.length;
      case _FilterTab.active:  return pre.where((e) => e.coupon.status == CouponStatus.pending).length;
      case _FilterTab.winning: return pre.where((e) => e.coupon.status == CouponStatus.winning).length;
      case _FilterTab.losing:  return pre.where((e) => e.coupon.status == CouponStatus.risk).length;
    }
  }

  List<_CouponEntry> get _filteredEntries {
    var list = _preFiltered;
    switch (_activeTab) {
      case _FilterTab.all:     break;
      case _FilterTab.active:  list = list.where((e) => e.coupon.status == CouponStatus.pending).toList();  break;
      case _FilterTab.winning: list = list.where((e) => e.coupon.status == CouponStatus.winning).toList(); break;
      case _FilterTab.losing:  list = list.where((e) => e.coupon.status == CouponStatus.risk).toList();    break;
    }
    list.sort((a, b) => a.isFavorite == b.isFavorite ? 0 : (a.isFavorite ? -1 : 1));
    return list;
  }

  String get _emptyMessage {
    if (_searchQuery.isNotEmpty) return 'Arama sonucu bulunamadı';
    if (_siteFilter   != 'Tümü') return '$_siteFilter kuponu bulunamadı';
    if (_leagueFilter != 'Tümü') return '$_leagueFilter kuponu bulunamadı';
    switch (_activeTab) {
      case _FilterTab.all:     return 'Henüz kupon eklenmedi';
      case _FilterTab.active:  return 'Aktif kupon bulunamadı';
      case _FilterTab.winning: return 'Kazanan kupon bulunamadı';
      case _FilterTab.losing:  return 'Kaybeden kupon bulunamadı';
    }
  }

  double get _totalPotential {
    double total = 0;
    for (final e in _entries) {
      final m = RegExp(r'₺(\d+(?:[.,]\d+)?)').firstMatch(e.coupon.potential);
      if (m != null) total += double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
    }
    return total;
  }

  String get _totalPotentialText {
    final n = _totalPotential.toInt();
    if (n <= 0) return '–';
    if (n >= 1000) return '₺${n ~/ 1000}.${(n % 1000).toString().padLeft(3, '0')}';
    return '₺$n';
  }

  // ── share helpers ──────────────────────────────────────────────────────────

  void _saveActiveSharedId(_CouponEntry entry, String id) {
    if (entry.coupon.sharedId != null) return;
    setState(() => entry.coupon = entry.coupon.copyWith(sharedId: id));
    _pushCouponToBackend(entry.coupon, id);
  }

  void _saveHistorySharedId(Coupon coupon, String id) {
    if (coupon.sharedId != null) return;
    final idx = _historyEntries.indexWhere(
      (e) => e.coupon.title == coupon.title && e.coupon.stake == coupon.stake,
    );
    if (idx == -1) return;
    setState(() => _historyEntries[idx].coupon =
        _historyEntries[idx].coupon.copyWith(sharedId: id));
    _pushCouponToBackend(coupon, id);
  }

  /// Fire-and-forget: register the shared coupon and upload its full detail.
  void _pushCouponToBackend(Coupon coupon, String id) {
    final owner = _currentUsername;
    SocialService.instance.createOrUpdateSharedCoupon(
      couponId: id,
      ownerUsername: owner,
    );
    final oddsMatch = RegExp(r'×([\d.,]+)').firstMatch(coupon.meta);
    SocialService.instance.saveCouponDetail(
      couponId:      id,
      ownerUsername: owner,
      title:         coupon.title,
      siteName:      coupon.meta.split('·').first.trim(),
      stake:         coupon.stake,
      odds:          oddsMatch != null ? '×${oddsMatch.group(1)}' : '',
      potential:     coupon.potential,
      status:        coupon.status.name,
      selections:    coupon.matches.map((m) => {
        'matchName': m.teams,
        'betType':   m.selection,
        'status':    m.status.name,
        'lastScore': m.score,
      }).toList(),
    );
  }

  // ── status update helpers ──────────────────────────────────────────────────

  void _updateActiveStatus(_CouponEntry entry, CouponStatus newStatus) {
    setState(() => entry.coupon = entry.coupon.copyWith(status: newStatus));
  }

  void _updateHistoryStatus(Coupon coupon, CouponStatus newStatus) {
    final idx = _historyEntries.indexWhere(
      (e) => e.coupon.title == coupon.title && e.coupon.stake == coupon.stake,
    );
    if (idx == -1) return;
    setState(() => _historyEntries[idx].coupon =
        _historyEntries[idx].coupon.copyWith(status: newStatus));
  }

  // ── actions ────────────────────────────────────────────────────────────────

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltersSheet(
        siteFilter: _siteFilter,
        leagueFilter: _leagueFilter,
        siteOptions: _siteOptions,
        leagueOptions: _leagueOptions,
        onSiteChanged: (v) => setState(() => _siteFilter = v),
        onLeagueChanged: (v) => setState(() => _leagueFilter = v),
      ),
    );
  }

  Future<void> _openAddSheet() async {
    final newCoupon = await showModalBottomSheet<Coupon>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCouponSheet(),
    );
    if (newCoupon == null) return;
    final savedCoupon = await CouponStorageService.instance.saveCoupon(newCoupon);
    setState(() => _entries.insert(0, _CouponEntry(coupon: savedCoupon ?? newCoupon)));
  }

  Future<void> _editEntry(_CouponEntry entry) async {
    final updated = await showModalBottomSheet<Coupon>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCouponSheet(initialCoupon: entry.coupon),
    );
    if (updated == null) return;
    setState(() => entry.coupon = updated);
  }

  Future<void> _deleteEntry(_CouponEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Kuponu Sil',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Bu kupon kalıcı olarak silinecek.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil',
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) setState(() => _entries.remove(entry));
  }

  List<Coupon> get _allCoupons => [
        ..._entries.map((e) => e.coupon),
        ..._historyEntries.map((e) => e.coupon),
      ];

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered     = _filteredEntries;
    final activeCount  = _tabCount(_FilterTab.active);
    final winningCount = _tabCount(_FilterTab.winning);
    final losingCount  = _tabCount(_FilterTab.losing);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: _navIndex == 1
                      ? FeedPage(username: _currentUsername)
                      : _navIndex == 2
                          ? IstatistikPage(
                              allCoupons: _allCoupons,
                            )
                          : _navIndex == 3
                              ? AyarlarPage(coupons: _allCoupons)
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                                  children: [

                                    // ── Header row ──────────────────────────
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Matchly',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const NotificationBell(),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Hero card ────────────────────────────
                                    _HeroCard(
                                      totalPotential: _totalPotentialText,
                                      activeCount: activeCount,
                                      winningCount: winningCount,
                                      losingCount: losingCount,
                                    ),
                                    const SizedBox(height: 22),

                                    // ── Search bar ───────────────────────────
                                    _HomeSearchBar(
                                      controller: _searchController,
                                      onChanged: (v) =>
                                          setState(() => _searchQuery = v),
                                      onClear: () => setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      }),
                                      onFilterTap: _openFiltersSheet,
                                      hasActiveFilters: _siteFilter != 'Tümü' ||
                                          _leagueFilter != 'Tümü',
                                    ),
                                    const SizedBox(height: 14),

                                    // ── Filter tabs ──────────────────────────
                                    _FilterTabBar(
                                      activeTab: _activeTab,
                                      tabLabel: _tabLabel,
                                      tabCount: _tabCount,
                                      onTabSelected: (tab) =>
                                          setState(() => _activeTab = tab),
                                    ),
                                    const SizedBox(height: 18),

                                    // ── Section label ────────────────────────
                                    SectionHeader(
                                      title: _tabLabel(_activeTab).toUpperCase(),
                                      live: _activeTab == _FilterTab.all ||
                                          _activeTab == _FilterTab.active,
                                    ),
                                    const SizedBox(height: 10),

                                    // ── List / empty state ───────────────────
                                    if (filtered.isEmpty)
                                      _EmptyState(message: _emptyMessage)
                                    else
                                      ...filtered.map(
                                        (entry) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 18),
                                          child: CouponCard(
                                            coupon: entry.coupon.copyWithMatches(_enrichMatches(entry.coupon.matches)),
                                            isFavorite: entry.isFavorite,
                                            onTap: () =>
                                                Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => CouponDetailPage(
                                                  coupon: entry.coupon.copyWithMatches(_enrichMatches(entry.coupon.matches)),
                                                  onSharedIdGenerated: (id) =>
                                                      _saveActiveSharedId(
                                                          entry, id),
                                                  onStatusChanged: (s) =>
                                                      _updateActiveStatus(
                                                          entry, s),
                                                  allCoupons: _allCoupons,
                                                ),
                                              ),
                                            ),
                                            onFavoriteToggle: () => setState(
                                                () => entry.isFavorite =
                                                    !entry.isFavorite),
                                            onEdit: () => _editEntry(entry),
                                            onShare: () => CouponShare.share(
                                              context,
                                              entry.coupon,
                                            ).then((id) =>
                                                _saveActiveSharedId(entry, id)),
                                            onDelete: () =>
                                                _deleteEntry(entry),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                ),
                BottomNav(
                  onAddPressed: _openAddSheet,
                  activeIndex: _navIndex,
                  onTabChanged: (i) => setState(() => _navIndex = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final String totalPotential;
  final int activeCount;
  final int winningCount;
  final int losingCount;

  const _HeroCard({
    required this.totalPotential,
    required this.activeCount,
    required this.winningCount,
    required this.losingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 38, 26, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.15, 1.0],
          colors: [
            const Color(0xFF1E1D1C),
            const Color(0xFF181716),
            const Color(0xFF101010),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFF0E8DA).withOpacity(0.30),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF0E8DA).withOpacity(0.07),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.65),
            blurRadius: 48,
            offset: const Offset(0, 22),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TOPLAM BEKLENTİ',
            style: TextStyle(
              color: const Color(0xFF6B6860),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            totalPotential,
            style: const TextStyle(
              color: Color(0xFFF5F3EE),
              fontSize: 62,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 26),
          Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.12),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.25, 0.75, 1.0],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatDot(count: activeCount,  label: 'aktif',     color: const Color(0xFF6B6860)),
              const _Sep(),
              _StatDot(count: winningCount, label: 'kazanıyor', color: AppColors.green),
              const _Sep(),
              _StatDot(count: losingCount,  label: 'kaybetti',  color: AppColors.red),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatDot({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7),
        child: Text('·', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      );
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  const _HomeSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF0E8DA);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Kupon ara...',
                hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Icon(Icons.close_rounded, color: AppColors.textTertiary, size: 16),
              ),
            ),
          // Filter button
          GestureDetector(
            onTap: onFilterTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: hasActiveFilters ? accent : AppColors.textTertiary,
                    size: 18,
                  ),
                  if (hasActiveFilters)
                    Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filters bottom sheet ─────────────────────────────────────────────────────

class _FiltersSheet extends StatefulWidget {
  final String siteFilter;
  final String leagueFilter;
  final List<String> siteOptions;
  final List<String> leagueOptions;
  final ValueChanged<String> onSiteChanged;
  final ValueChanged<String> onLeagueChanged;

  const _FiltersSheet({
    required this.siteFilter,
    required this.leagueFilter,
    required this.siteOptions,
    required this.leagueOptions,
    required this.onSiteChanged,
    required this.onLeagueChanged,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String _site;
  late String _league;

  bool get _hasActive => _site != 'Tümü' || _league != 'Tümü';

  @override
  void initState() {
    super.initState();
    _site   = widget.siteFilter;
    _league = widget.leagueFilter;
  }

  void _selectSite(String v) {
    setState(() => _site = v);
    widget.onSiteChanged(v);
  }

  void _selectLeague(String v) {
    setState(() => _league = v);
    widget.onLeagueChanged(v);
  }

  void _reset() {
    setState(() { _site = 'Tümü'; _league = 'Tümü'; });
    widget.onSiteChanged('Tümü');
    widget.onLeagueChanged('Tümü');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
            child: Row(
              children: [
                const Text(
                  'Filtreler',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _hasActive ? _reset : null,
                  style: TextButton.styleFrom(
                    foregroundColor: _hasActive
                        ? const Color(0xFFF0E8DA)
                        : AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Sıfırla'),
                ),
              ],
            ),
          ),
          // ── Filter sections ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterSection(
                  label: 'SİTE',
                  options: widget.siteOptions,
                  selected: _site,
                  onSelect: _selectSite,
                ),
                const SizedBox(height: 20),
                _FilterSection(
                  label: 'LİG',
                  options: widget.leagueOptions,
                  selected: _league,
                  onSelect: _selectLeague,
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 28),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterSection({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
          ),
          child: Column(
            children: options.asMap().entries.map((entry) {
              final i          = entry.key;
              final opt        = entry.value;
              final isSelected = opt == selected;
              final isFirst    = i == 0;
              final isLast     = i == options.length - 1;
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.vertical(
                        top:    isFirst ? const Radius.circular(16) : Radius.zero,
                        bottom: isLast  ? const Radius.circular(16) : Radius.zero,
                      ),
                      onTap: () => onSelect(opt),
                      highlightColor: Colors.white.withOpacity(0.04),
                      splashColor:    Colors.white.withOpacity(0.04),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Text(
                              opt,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                color: Color(0xFFF0E8DA),
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      height: 0.5,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.white.withOpacity(0.06),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Filter tab bar ───────────────────────────────────────────────────────────

class _FilterTabBar extends StatelessWidget {
  final _FilterTab activeTab;
  final String Function(_FilterTab) tabLabel;
  final int Function(_FilterTab) tabCount;
  final ValueChanged<_FilterTab> onTabSelected;

  const _FilterTabBar({
    required this.activeTab,
    required this.tabLabel,
    required this.tabCount,
    required this.onTabSelected,
  });

  Widget _pill(_FilterTab tab) {
    final isActive = tab == activeTab;
    final count    = tabCount(tab);
    const accent   = Color(0xFFF0E8DA);

    return GestureDetector(
      onTap: () => onTabSelected(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF232019) : const Color(0xFF0F0F0E),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? accent.withOpacity(0.28) : Colors.white.withOpacity(0.07),
            width: 0.6,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: accent.withOpacity(0.07), blurRadius: 12)]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tabLabel(tab),
                style: TextStyle(
                  color: isActive ? const Color(0xFFF0EBE0) : AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive ? accent.withOpacity(0.13) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isActive ? const Color(0xFFD6C4A8) : AppColors.textTertiary,
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
        Expanded(child: _pill(_FilterTab.all)),
        gap,
        Expanded(child: _pill(_FilterTab.active)),
        gap,
        Expanded(child: _pill(_FilterTab.winning)),
        gap,
        Expanded(child: _pill(_FilterTab.losing)),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('📭', style: TextStyle(fontSize: 36, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yeni bir kupon oluşturmak için + butonuna dokun.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
