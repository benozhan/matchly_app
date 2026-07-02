import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/coupon_share.dart';
import '../../core/starting_balance_dialog.dart';
import '../../l10n/app_localizations.dart';
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
import '../profile/shared_coupon_detail_page.dart';
import '../istatistik/istatistik_page.dart';
import 'bottom_nav.dart';
import 'notification_bell.dart';
import 'coupon_card.dart';
import 'section_header.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

enum _FilterTab { all, active, winning, losing }

class _CouponEntry {
  Coupon coupon;
  bool isFavorite = false;
  _CouponEntry({required this.coupon});
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

  _FilterTab _activeTab = _FilterTab.active;
  int _navIndex = 0;
  final ScrollController _scrollController = ScrollController();

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
                      (s) =>
                          s.name ==
                          ((m['status'] ?? 'pending') == 'void'
                              ? 'void_'
                              : (m['status'] ?? 'pending')),
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
                  entry.coupon = entry.coupon
                      .copyWithMatches(matches)
                      .copyWith(status: status);
                }
              }
            });
          },
        )
        .subscribe();

    // coupon_matches realtime
    _matchChannel = Supabase.instance.client
        .channel('coupon_matches:$userId')
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
                      (s) =>
                          s.name ==
                          ((m['status'] ?? 'pending') == 'void'
                              ? 'void_'
                              : (m['status'] ?? 'pending')),
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

  String _searchQuery = '';
  String _siteFilter = 'Tümü';
  String _leagueFilter = 'Tümü';

  AppUser? _user;

  String get _currentUsername => _user?.username ?? 'ozhan';

  late TextEditingController _searchController;

  static const _siteOptions = ['Tümü', 'Bilyoner', 'Misli', 'Nesine', 'Betano'];
  static const _leagueOptions = [
    'Tümü',
    'Dünya Kupası',
    'Şampiyonlar Ligi',
    'Premier Lig',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadUser();
    _startLiveScoreTimer();
    _startPeriodicRefresh();
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
    final entry = _entries.cast<_CouponEntry?>().firstWhere(
      (e) => e?.coupon.id == couponId,
      orElse: () => _historyEntries.cast<_CouponEntry?>().firstWhere(
        (e) => e?.coupon.id == couponId,
        orElse: () => null,
      ),
    );
    if (entry != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CouponDetailPage(
            coupon: entry.coupon,
            resolved: entry.coupon.status != CouponStatus.pending,
            allCoupons: _entries.map((e) => e.coupon).toList(),
          ),
        ),
      );
      return;
    }
    // Kendi listemizde yok — başkasının paylaştığı kupon olabilir,
    // paylaşılan kupon detay sayfasına düş.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SharedCouponDetailPage(
          sharedCoupon: SharedCoupon(
            id: couponId,
            couponId: couponId,
            isPublic: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        ),
      ),
    );
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
        await SocialService.instance.ensureUser(
          user.username,
          user.displayName,
        );
      } catch (_) {}
    }

    // Bildirimden gelen kupon — entries yüklendikten sonra aç
    if (widget.pendingCouponId != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCouponById(widget.pendingCouponId!);
      });
    } else {
      _maybePromptStartingBalance();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _liveTimer?.cancel();
    _couponChannel?.unsubscribe();
    _matchChannel?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  // ── live scores ────────────────────────────────────────────────────────────

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () async {
      if (!mounted) return;
      await _loadUser();
      _startPeriodicRefresh();
    });
  }

  void _startLiveScoreTimer() {
    _fetchLiveScores();
    _liveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchLiveScores(),
    );
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
      final selNorm = m.selection.toLowerCase();
      final isCornerOrCard =
          selNorm.contains('korner') || selNorm.contains('kart');
      // Korner/kart bahislerinde backend'den gelen detaylı skoru koru, maç skoruyla override etme
      if (isCornerOrCard) {
        return MatchItem(
          teams: m.teams,
          selection: m.selection,
          score: m.score,
          minute: live.isLive ? live.minute : m.minute,
          status: m.status,
        );
      }
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
    if (t.contains('şampiyonlar') || t.contains('champions'))
      return 'Şampiyonlar Ligi';
    if (t.contains('premier')) return 'Premier Lig';
    return 'Diğer';
  }

  // ── computed ───────────────────────────────────────────────────────────────

  String _tabLabel(_FilterTab tab) {
    final t = AppLocalizations.of(context)!;
    switch (tab) {
      case _FilterTab.all:
        return t.tabAll;
      case _FilterTab.active:
        return t.active;
      case _FilterTab.winning:
        return t.wonLabel;
      case _FilterTab.losing:
        return t.lostLabel;
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
        return c.matches.any(
          (m) =>
              m.teams.toLowerCase().contains(q) ||
              m.selection.toLowerCase().contains(q),
        );
      }).toList();
    }

    if (_siteFilter != 'Tümü') {
      list = list.where((e) => _parseSite(e.coupon) == _siteFilter).toList();
    }

    if (_leagueFilter != 'Tümü') {
      list = list
          .where((e) => _detectLeague(e.coupon) == _leagueFilter)
          .toList();
    }

    return list;
  }

  int _tabCount(_FilterTab tab) {
    final pre = _preFiltered;
    switch (tab) {
      case _FilterTab.all:
        return pre.length;
      case _FilterTab.active:
        return pre.where((e) => e.coupon.status == CouponStatus.pending).length;
      case _FilterTab.winning:
        return pre.where((e) => e.coupon.status == CouponStatus.winning).length;
      case _FilterTab.losing:
        return pre.where((e) => e.coupon.status == CouponStatus.risk).length;
    }
  }

  List<_CouponEntry> get _filteredEntries {
    var list = _preFiltered;
    switch (_activeTab) {
      case _FilterTab.all:
        break;
      case _FilterTab.active:
        list = list
            .where((e) => e.coupon.status == CouponStatus.pending)
            .toList();
        break;
      case _FilterTab.winning:
        list = list
            .where((e) => e.coupon.status == CouponStatus.winning)
            .toList();
        break;
      case _FilterTab.losing:
        list = list.where((e) => e.coupon.status == CouponStatus.risk).toList();
        break;
    }
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      final aDate = a.coupon.createdAt;
      final bDate = b.coupon.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  String get _emptyMessage {
    final t = AppLocalizations.of(context)!;
    if (_searchQuery.isNotEmpty) return t.searchNoResults;
    if (_siteFilter != 'Tümü') return '$_siteFilter kuponu bulunamadı';
    if (_leagueFilter != 'Tümü') return '$_leagueFilter kuponu bulunamadı';
    switch (_activeTab) {
      case _FilterTab.all:
        return t.noCouponsYet;
      case _FilterTab.active:
        return t.noActiveCoupons;
      case _FilterTab.winning:
        return t.noWinningCoupons;
      case _FilterTab.losing:
        return t.noLosingCoupons;
    }
  }

  double get _totalPotential {
    double total = 0;
    for (final e in _entries) {
      if (e.coupon.status != CouponStatus.pending) continue;
      final m = RegExp(r'₺(\d+(?:[.,]\d+)?)').firstMatch(e.coupon.potential);
      if (m != null)
        total += double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
    }
    return total;
  }

  String get _totalPotentialText {
    final n = _totalPotential.toInt();
    if (n <= 0) return '–';
    if (n >= 1000)
      return '₺${n ~/ 1000}.${(n % 1000).toString().padLeft(3, '0')}';
    return '₺$n';
  }

  // ── Bugünkü istatistikler ──────────────────────────────────────────────────
  DateTime get _effectiveToday {
    final now = DateTime.now();
    // 03:00'dan önce ise hala "dün" sayılır
    if (now.hour < 3) return now.subtract(const Duration(days: 1));
    return now;
  }

  List<Coupon> get _todayCoupons {
    final today = _effectiveToday;
    return _entries.map((e) => e.coupon).where((c) {
      if (c.createdAt == null) return false;
      return c.createdAt!.year == today.year &&
          c.createdAt!.month == today.month &&
          c.createdAt!.day == today.day;
    }).toList();
  }

  List<Coupon> get _yesterdayCoupons {
    final yesterday = _effectiveToday.subtract(const Duration(days: 1));
    return _entries.map((e) => e.coupon).where((c) {
      if (c.createdAt == null) return false;
      return c.createdAt!.year == yesterday.year &&
          c.createdAt!.month == yesterday.month &&
          c.createdAt!.day == yesterday.day;
    }).toList();
  }

  Map<String, dynamic> _calcStats(List<Coupon> coupons) {
    double stake = 0, profit = 0;
    int won = 0, lost = 0;
    for (final c in coupons) {
      final s =
          double.tryParse(
            RegExp(r'₺([\d]+)').firstMatch(c.stake)?.group(1) ?? '0',
          ) ??
          0;
      stake += s;
      if (c.status == CouponStatus.winning) {
        final p =
            double.tryParse(
              RegExp(r'₺([\d]+)').firstMatch(c.potential)?.group(1) ?? '0',
            ) ??
            0;
        profit += p - s;
        won++;
      } else if (c.status == CouponStatus.risk) {
        profit -= s;
        lost++;
      }
    }
    return {
      'stake': stake,
      'profit': profit,
      'won': won,
      'lost': lost,
      'total': coupons.length,
    };
  }

  Map<String, dynamic> get _todayStats => _calcStats(_todayCoupons);
  Map<String, dynamic> get _yesterdayStats => _calcStats(_yesterdayCoupons);

  // ── share helpers ──────────────────────────────────────────────────────────

  void _saveActiveSharedId(_CouponEntry entry, String id) {
    if (entry.coupon.sharedId != null) return;
    setState(() => entry.coupon = entry.coupon.copyWith(sharedId: id));
    _pushCouponToBackend(entry.coupon, id);
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
      couponId: id,
      ownerUsername: owner,
      title: coupon.title,
      siteName: coupon.meta.split('·').first.trim(),
      stake: coupon.stake,
      odds: oddsMatch != null ? '×${oddsMatch.group(1)}' : '',
      potential: coupon.potential,
      status: coupon.status.name,
      selections: coupon.matches
          .map(
            (m) => {
              'matchName': m.teams,
              'betType': m.selection,
              'status': m.status.name,
              'lastScore': m.score,
            },
          )
          .toList(),
    );
  }

  // ── status update helpers ──────────────────────────────────────────────────

  void _updateActiveStatus(_CouponEntry entry, CouponStatus newStatus) {
    setState(() => entry.coupon = entry.coupon.copyWith(status: newStatus));
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
    setState(() => _entries.insert(0, _CouponEntry(coupon: newCoupon)));
    _loadUser(); // Arka planda yenile
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

  Future<void> _togglePublic(_CouponEntry entry) async {
    final newVal = !entry.coupon.isPublic;
    final couponId = entry.coupon.id;
    if (couponId == null || _user == null) return;
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    setState(() => entry.coupon = entry.coupon.copyWith(isPublic: newVal));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(scrollOffset);
      }
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newVal ? t.sharedToFeedMessage : t.removedFromFeedMessage,
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    await Supabase.instance.client
        .from('coupons')
        .update({'is_public': newVal})
        .eq('id', couponId);
    try {
      if (newVal) {
        await SocialService.instance.createOrUpdateSharedCoupon(
          couponId: couponId,
          ownerUsername: _user!.username,
          isPublic: true,
        );
      } else {
        await SocialService.instance.createOrUpdateSharedCoupon(
          couponId: couponId,
          ownerUsername: _user!.username,
          isPublic: false,
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteEntry(_CouponEntry entry) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.deleteCouponTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          t.deleteCouponBody,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t.cancelLabel,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.deleteLabel,
              style: TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _entries.remove(entry));
      if (entry.coupon.id != null) {
        // Önce is_public kapat (feed'den kaldır)
        if (entry.coupon.isPublic) {
          await Supabase.instance.client
              .from('coupons')
              .update({'is_public': false})
              .eq('id', entry.coupon.id!);
        }
        await CouponStorageService.instance.deleteCoupon(entry.coupon.id!);
      }
    }
  }

  List<Coupon> get _allCoupons => [
    ..._entries.map((e) => e.coupon),
    ..._historyEntries.map((e) => e.coupon),
  ];

  Map<String, dynamic> get _allTimeStats => _calcStats(_allCoupons);

  int get _winRatePct {
    final s = _allTimeStats;
    final resolved = (s['won'] as int) + (s['lost'] as int);
    return resolved > 0 ? ((s['won'] as int) / resolved * 100).round() : 0;
  }

  double get _netProfit => _allTimeStats['profit'] as double;

  // ── kasa (bakiye) ──────────────────────────────────────────────────────────

  double? get _kasa {
    final starting = _user?.startingBalance;
    if (starting == null) return null;
    final baseline = _user!.netProfitBaseline ?? 0;
    return starting + (_netProfit - baseline);
  }

  bool _hasPromptedBalance = false;

  Future<void> _maybePromptStartingBalance() async {
    if (_hasPromptedBalance || _user == null || _user!.startingBalance != null) return;
    _hasPromptedBalance = true;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await _editStartingBalance();
  }

  Future<void> _editStartingBalance() async {
    final value = await showStartingBalanceDialog(
      context,
      current: _user?.startingBalance,
    );
    if (value == null) return;
    final baseline = _netProfit;
    await AuthService.instance.updateStartingBalance(value, baseline);
    if (!mounted) return;
    setState(() {
      _user = _user?.copyWith(startingBalance: value, netProfitBaseline: baseline);
    });
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final filtered = _filteredEntries;
    final activeCount = _tabCount(_FilterTab.active);

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
                      ? IstatistikPage(allCoupons: _allCoupons)
                      : _navIndex == 3
                      ? AyarlarPage(coupons: _allCoupons)
                      : RefreshIndicator(
                          onRefresh: () => _loadUser(),
                          color: AppColors.brand,
                          child: ListView(
                            controller: _scrollController,
                            key: const PageStorageKey('home_list'),
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                            children: [
                              // ── Header row ──────────────────────────
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    t.appName,
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
                                kasa: _kasa,
                                totalPotential: _totalPotentialText,
                                activeCount: activeCount,
                                winRatePct: _winRatePct,
                                netProfit: _netProfit,
                                todayStats: _todayStats,
                                yesterdayStats: _yesterdayStats,
                                onKasaTap: _editStartingBalance,
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
                                hasActiveFilters:
                                    _siteFilter != 'Tümü' ||
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
                                live:
                                    _activeTab == _FilterTab.all ||
                                    _activeTab == _FilterTab.active,
                              ),
                              const SizedBox(height: 10),

                              // ── List / empty state ───────────────────
                              if (filtered.isEmpty)
                                _EmptyState(message: _emptyMessage)
                              else
                                ...filtered.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: CouponCard(
                                      coupon: entry.coupon.copyWithMatches(
                                        _enrichMatches(entry.coupon.matches),
                                      ),
                                      isFavorite: entry.isFavorite,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CouponDetailPage(
                                            coupon: entry.coupon
                                                .copyWithMatches(
                                                  _enrichMatches(
                                                    entry.coupon.matches,
                                                  ),
                                                ),
                                            onSharedIdGenerated: (id) =>
                                                _saveActiveSharedId(entry, id),
                                            onStatusChanged: (s) =>
                                                _updateActiveStatus(entry, s),
                                            allCoupons: _allCoupons,
                                          ),
                                        ),
                                      ),
                                      onFavoriteToggle: () => setState(
                                        () => entry.isFavorite =
                                            !entry.isFavorite,
                                      ),
                                      onEdit: () => _editEntry(entry),
                                      onShare: () =>
                                          CouponShare.share(
                                            context,
                                            entry.coupon,
                                          ).then(
                                            (id) =>
                                                _saveActiveSharedId(entry, id),
                                          ),
                                      onDelete: () => _deleteEntry(entry),
                                      onPublicToggle: () =>
                                          _togglePublic(entry),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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

String _formatMoney(double amount) {
  final n = amount.toInt();
  final sign = n < 0 ? '-' : '';
  final abs = n.abs();
  if (abs >= 1000) {
    return '$sign₺${abs ~/ 1000}.${(abs % 1000).toString().padLeft(3, '0')}';
  }
  return '$sign₺$abs';
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final double? kasa;
  final String totalPotential;
  final int activeCount;
  final int winRatePct;
  final double netProfit;
  final Map<String, dynamic> todayStats;
  final Map<String, dynamic> yesterdayStats;
  final VoidCallback onKasaTap;

  const _HeroCard({
    required this.kasa,
    required this.totalPotential,
    required this.activeCount,
    required this.winRatePct,
    required this.netProfit,
    required this.todayStats,
    required this.yesterdayStats,
    required this.onKasaTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 38, 26, 32),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(0.25),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            t.heroKasaLabel,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onKasaTap,
            behavior: HitTestBehavior.opaque,
            child: kasa != null
                ? Text(
                    _formatMoney(kasa!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 62,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.5,
                      height: 1.0,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.kasaNotSetLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.add_circle_rounded, color: Colors.white, size: 22),
                      ],
                    ),
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
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 8,
            children: [
              _StatDot(
                value: '$activeCount',
                label: t.activeStatLabel,
                color: const Color(0xFF6B6860),
              ),
              const _Sep(),
              _StatDot(
                value: '%$winRatePct',
                label: t.successStatLabel,
                color: AppColors.green,
              ),
              const _Sep(),
              _StatDot(
                value:
                    '${netProfit >= 0 ? '+' : '-'}₺${netProfit.abs().toInt()}',
                label: t.netStatLabel,
                color: netProfit >= 0 ? AppColors.green : AppColors.red,
              ),
              const _Sep(),
              _StatDot(
                value: totalPotential,
                label: t.potentialStatLabel,
                color: Colors.white.withOpacity(0.85),
              ),
            ],
          ),
          if ((todayStats['total'] as int) > 0 ||
              (yesterdayStats['total'] as int) > 0) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TodayStat(
                    label: (todayStats['total'] as int) == 0 ? t.yesterdayLabel : t.todayLabel,
                    value: t.couponCountSuffix(
                      (todayStats['total'] as int) == 0 ? yesterdayStats['total'] as int : todayStats['total'] as int,
                    ),
                  ),
                  _TodayStat(
                    label: t.investmentLabel,
                    value: '₺${(todayStats['stake'] as double).toInt()}',
                  ),
                  _TodayStat(
                    label: t.profitLossLabel,
                    value: () {
                      final p = todayStats['profit'] as double;
                      if (p == 0) return '–';
                      final prefix = p > 0 ? '+' : '';
                      return '${prefix}₺${p.toInt().abs()}';
                    }(),
                    valueColor: (todayStats['profit'] as double) > 0
                        ? Colors.greenAccent
                        : (todayStats['profit'] as double) < 0
                        ? Colors.redAccent
                        : Colors.white,
                  ),
                ],
              ),
            ),
            if ((yesterdayStats['total'] as int) > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TodayStat(
                      label: t.yesterdayLabel,
                      value: t.couponCountSuffix(yesterdayStats['total'] as int),
                    ),
                    _TodayStat(
                      label: t.investmentLabel,
                      value: '₺${(yesterdayStats['stake'] as double).toInt()}',
                    ),
                    _TodayStat(
                      label: t.profitLossLabel,
                      value: () {
                        final p = yesterdayStats['profit'] as double;
                        if (p == 0) return '–';
                        final prefix = p > 0 ? '+' : '';
                        return '${prefix}₺${p.toInt().abs()}';
                      }(),
                      valueColor: (yesterdayStats['profit'] as double) > 0
                          ? Colors.greenAccent
                          : (yesterdayStats['profit'] as double) < 0
                          ? Colors.redAccent
                          : Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _TodayStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatDot extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatDot({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 7),
    child: Text(
      '·',
      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
    ),
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
    final t = AppLocalizations.of(context)!;
    const accent = Color(0xFFF0E8DA);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: t.searchHint,
                hintStyle: TextStyle(
                  color: AppColors.textTertiary.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
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
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
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
    _site = widget.siteFilter;
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
    setState(() {
      _site = 'Tümü';
      _league = 'Tümü';
    });
    widget.onSiteChanged('Tümü');
    widget.onLeagueChanged('Tümü');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
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
                Text(
                  t.filtersTitle,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(t.resetLabel),
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
                  label: t.filterSiteLabel,
                  options: widget.siteOptions,
                  selected: _site,
                  onSelect: _selectSite,
                ),
                const SizedBox(height: 20),
                _FilterSection(
                  label: t.filterLeagueLabel,
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
          style: TextStyle(
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
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            children: options.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              final isSelected = opt == selected;
              final isFirst = i == 0;
              final isLast = i == options.length - 1;
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.vertical(
                        top: isFirst ? const Radius.circular(16) : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                      onTap: () => onSelect(opt),
                      highlightColor: AppColors.border,
                      splashColor: AppColors.border,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
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
                      color: AppColors.border,
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
        Expanded(child: _pill(_FilterTab.active)),
        gap,
        Expanded(child: _pill(_FilterTab.winning)),
        gap,
        Expanded(child: _pill(_FilterTab.losing)),
        gap,
        Expanded(child: _pill(_FilterTab.all)),
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
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 36,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.emptyStateHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
