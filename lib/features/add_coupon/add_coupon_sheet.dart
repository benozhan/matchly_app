import 'dart:async';

import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/coupon_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ai_coupon_service.dart';
import '../../core/coupon_share.dart';

import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/coupon.dart';
import '../../services/match_search_service.dart';

const _mockMatches = [
  'Galatasaray - Fenerbahçe',
  'Beşiktaş - Trabzonspor',
  'Türkiye - Paraguay',
  'Arsenal - Chelsea',
  'Barcelona - Real Madrid',
  'Brazil - Haiti',
  'Canada - Qatar',
  'Belgium - Iran',
  'Mexico - South Korea',
  'Czechia - South Africa',
  'Uzbekistan - Colombia',
];

// ─── League list ─────────────────────────────────────────────────────────────

const _leagues = [
  // Türkiye
  'Süper Lig',
  'TFF 1. Lig',
  'TFF 2. Lig',
  'Türkiye Kupası',
  // İngiltere
  'Premier Lig',
  'Championship',
  'League One',
  'FA Cup',
  // İspanya
  'La Liga',
  'La Liga 2',
  'Copa del Rey',
  // İtalya
  'Serie A',
  'Serie B',
  'Coppa Italia',
  // Almanya
  'Bundesliga',
  '2. Bundesliga',
  'DFB Pokal',
  // Fransa
  'Ligue 1',
  'Ligue 2',
  'Coupe de France',
  // Hollanda
  'Eredivisie',
  'Eerste Divisie',
  // Portekiz
  'Primeira Liga',
  // Belçika
  'Pro League',
  // İskoçya
  'Scottish Premiership',
  // Rusya
  'Premier Lig (Rusya)',
  // Türkiye dışı Avrupa
  'Süper Lig (Avusturya)',
  'Super League (İsviçre)',
  'Ekstraklasa (Polonya)',
  'Liga I (Romanya)',
  'Superliga (Sırbistan)',
  'Süper Lig (Yunanistan)',
  // Avrupa Kupaları
  'Şampiyonlar Ligi',
  'UEFA Avrupa Ligi',
  'Konferans Ligi',
  'UEFA Süper Kupası',
  // Milli Takım
  'Dünya Kupası',
  'Avrupa Şampiyonası',
  'Uluslar Ligi',
  'Afrika Kupası',
  'Copa America',
  'Asya Kupası',
  'Dünya Kupası Elemeleri',
  // Amerika
  'MLS',
  'Liga MX',
  'Brasileirao',
  'Argentine Primera',
  // Asya
  'J-League',
  'K-League',
  'Saudi Pro League',
  'CSL (Çin)',
  // Diğer
  'Diğer',
];

const _popularLeagues = [
  'süper lig',
  'premier lig',
  'premier league',
  'la liga',
  'serie a',
  'bundesliga',
  'ligue 1',
  'şampiyonlar ligi',
  'champions league',
  'avrupa ligi',
  'europa league',
  'dünya kupası',
  'world cup',
  'türkiye',
  'i̇ngiltere',
  'ingiltere',
  'i̇spanya',
  'ispanya',
  'i̇talya',
  'italya',
  'almanya',
  'fransa',
];

int _leaguePriority(String league) {
  final l = league.toLowerCase();
  for (var i = 0; i < _popularLeagues.length; i++) {
    if (l.contains(_popularLeagues[i])) return i;
  }
  return 999;
}

List<_MatchDisplay> _sortMatches(
  List<_MatchDisplay> matches,
  List<String> recentTeams,
) {
  final list = [...matches];
  list.sort((a, b) {
    final aRecent = recentTeams.contains(a.teams);
    final bRecent = recentTeams.contains(b.teams);
    if (aRecent != bRecent) return aRecent ? -1 : 1;
    final aPrio = _leaguePriority(a.league);
    final bPrio = _leaguePriority(b.league);
    if (aPrio != bPrio) return aPrio.compareTo(bPrio);
    return 0;
  });
  return list;
}

class _Market {
  final String name;
  final List<String>? lines;
  final List<String> options;

  const _Market({required this.name, this.lines, required this.options});

  bool get hasLines => lines != null;

  String buildBetText(String option, [String? line]) =>
      line == null ? option : '$option $line';
}

final _markets = [
  const _Market(name: 'Maç Sonucu', options: ['MS1', 'MSX', 'MS2']),
  const _Market(name: 'İlk Yarı Sonucu', options: ['İY 1', 'İY X', 'İY 2']),
  const _Market(
    name: 'Alt / Üst',
    lines: ['0.5', '1.5', '2.5', '3.5', '4.5', '5.5', '6.5'],
    options: ['Üst', 'Alt'],
  ),
  const _Market(
    name: 'İlk Yarı Alt / Üst',
    lines: ['0.5', '1.5', '2.5', '3.5'],
    options: ['İY Üst', 'İY Alt'],
  ),
  const _Market(name: 'KG', options: ['KG Var', 'KG Yok']),
  const _Market(
    name: 'Korner Alt / Üst',
    lines: ['5.5', '6.5', '7.5', '8.5', '9.5', '10.5', '11.5', '12.5', '13.5'],
    options: ['Korner Üst', 'Korner Alt'],
  ),
  const _Market(
    name: 'İlk Yarı Korner Alt / Üst',
    lines: ['0.5', '1.5', '2.5', '3.5', '4.5', '5.5', '6.5'],
    options: ['İY Korner Üst', 'İY Korner Alt'],
  ),
  const _Market(
    name: 'Sarı Kart Alt / Üst',
    lines: ['2.5', '3.5', '4.5', '5.5', '6.5'],
    options: ['Sarı Kart Üst', 'Sarı Kart Alt'],
  ),
  const _Market(
    name: 'İlk Yarı Sarı Kart Alt / Üst',
    lines: ['0.5', '1.5', '2.5', '3.5'],
    options: ['İY Sarı Kart Üst', 'İY Sarı Kart Alt'],
  ),
];

// ─── Search state ─────────────────────────────────────────────────────────────

enum _SearchState { idle, loading, success, error }

// ─── League name localisation ─────────────────────────────────────────────────

String _trLeague(String raw, String langCode) {
  if (langCode == 'en') return raw;
  const map = {
    'fifa world cup': 'Dünya Kupası',
    'world cup': 'Dünya Kupası',
    'uefa champions league': 'Şampiyonlar Ligi',
    'champions league': 'Şampiyonlar Ligi',
    'uefa europa league': 'UEFA Avrupa Ligi',
    'europa league': 'UEFA Avrupa Ligi',
    'uefa conference league': 'Konferans Ligi',
    'premier league': 'Premier Lig',
    'la liga': 'La Liga',
    'serie a': 'Serie A',
    'bundesliga': 'Bundesliga',
    'ligue 1': 'Ligue 1',
    'süper lig': 'Süper Lig',
    'super lig': 'Süper Lig',
  };
  return map[raw.toLowerCase()] ?? raw;
}

// ─── Date format ──────────────────────────────────────────────────────────────

/// Converts "2026-06-26 02:00" → "26 Haz 02:00" (or "26 Jun 02:00" in English)
String _trDate(String raw, String langCode) {
  const monthsTr = [
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
  const monthsEn = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final months = langCode == 'en' ? monthsEn : monthsTr;
  // Expect "YYYY-MM-DD HH:MM" or "YYYY-MM-DDTHH:MM"
  final re = RegExp(r'(\d{4})-(\d{2})-(\d{2})[ T](\d{2}:\d{2})');
  final m = re.firstMatch(raw);
  if (m == null) return raw;
  final month = int.tryParse(m.group(2)!) ?? 0;
  final day = int.tryParse(m.group(3)!) ?? 0;
  final time = m.group(4)!;
  if (month < 1 || month > 12) return raw;
  return '$day ${months[month]} $time';
}

// ─── Team / country name localisation ───────────────────────────────────────
// AUTO-GENERATED from kuponbot/country_names.py — do not edit by hand.
// To update: run  python3 kuponbot/gen_dart_countries.py  and paste the output.

String _trTeam(String raw, String langCode) {
  if (langCode == 'en') return raw;
  const map = <String, String>{
    'afghanistan': 'Afganistan',
    'albania': 'Arnavutluk',
    'algeria': 'Cezayir',
    'andorra': 'Andorra',
    'angola': 'Angola',
    'argentina': 'Arjantin',
    'armenia': 'Ermenistan',
    'australia': 'Avustralya',
    'austria': 'Avusturya',
    'azerbaijan': 'Azerbaycan',
    'bahrain': 'Bahreyn',
    'belarus': 'Belarus',
    'belgium': 'Belçika',
    'belize': 'Belize',
    'benin': 'Benin',
    'bolivia': 'Bolivya',
    'bosnia and herzegovina': 'Bosna Hersek',
    'bosnia-herzegovina': 'Bosna Hersek',
    'botswana': 'Botsvana',
    'brazil': 'Brezilya',
    'bulgaria': 'Bulgaristan',
    'burkina faso': 'Burkina Faso',
    'burundi': 'Burundi',
    'cameroon': 'Kamerun',
    'canada': 'Kanada',
    'cape verde': 'Yeşil Burun Adaları',
    'central african republic': 'Orta Afrika Cumhuriyeti',
    'chad': 'Çad',
    'chile': 'Şili',
    'china': 'Çin',
    'colombia': 'Kolombiya',
    'comoros': 'Komorlar',
    'congo': 'Kongo',
    'congo dr': 'Demokratik Kongo',
    'costa rica': 'Kosta Rika',
    'croatia': 'Hırvatistan',
    'cuba': 'Küba',
    'curacao': 'Curaçao',
    'curaçao': 'Curaçao',
    'cyprus': 'Kıbrıs',
    'czech republic': 'Çekya',
    'czechia': 'Çekya',
    "côte d'ivoire": 'Fildişi Sahili',
    'denmark': 'Danimarka',
    'djibouti': 'Cibuti',
    'dominican republic': 'Dominik Cumhuriyeti',
    'dr congo': 'Demokratik Kongo',
    'ecuador': 'Ekvador',
    'egypt': 'Mısır',
    'el salvador': 'El Salvador',
    'england': 'İngiltere',
    'equatorial guinea': 'Ekvator Ginesi',
    'eritrea': 'Eritre',
    'estonia': 'Estonya',
    'eswatini': 'Esvatini',
    'ethiopia': 'Etiyopya',
    'faroe islands': 'Faroe Adaları',
    'fiji': 'Fiji',
    'finland': 'Finlandiya',
    'france': 'Fransa',
    'gabon': 'Gabon',
    'gambia': 'Gambiya',
    'georgia': 'Gürcistan',
    'germany': 'Almanya',
    'ghana': 'Gana',
    'gibraltar': 'Cebelitarık',
    'greece': 'Yunanistan',
    'guatemala': 'Guatemala',
    'guinea': 'Gine',
    'guinea-bissau': 'Gine-Bissau',
    'guyana': 'Guyana',
    'haiti': 'Haiti',
    'honduras': 'Honduras',
    'hungary': 'Macaristan',
    'iceland': 'İzlanda',
    'india': 'Hindistan',
    'indonesia': 'Endonezya',
    'iran': 'İran',
    'iraq': 'Irak',
    'ireland': 'İrlanda',
    'israel': 'İsrail',
    'italy': 'İtalya',
    'ivory coast': 'Fildişi Sahili',
    'jamaica': 'Jamaika',
    'japan': 'Japonya',
    'jordan': 'Ürdün',
    'kazakhstan': 'Kazakistan',
    'kenya': 'Kenya',
    'korea republic': 'Güney Kore',
    'kosovo': 'Kosova',
    'kuwait': 'Kuveyt',
    'latvia': 'Letonya',
    'lebanon': 'Lübnan',
    'lesotho': 'Lesoto',
    'liberia': 'Liberya',
    'libya': 'Libya',
    'liechtenstein': 'Lihtenştayn',
    'lithuania': 'Litvanya',
    'luxembourg': 'Lüksemburg',
    'madagascar': 'Madagaskar',
    'malawi': 'Malavi',
    'malaysia': 'Malezya',
    'mali': 'Mali',
    'malta': 'Malta',
    'mauritania': 'Moritanya',
    'mauritius': 'Mauritius',
    'mexico': 'Meksika',
    'moldova': 'Moldova',
    'montenegro': 'Karadağ',
    'morocco': 'Fas',
    'mozambique': 'Mozambik',
    'myanmar': 'Myanmar',
    'namibia': 'Namibya',
    'netherlands': 'Hollanda',
    'new zealand': 'Yeni Zelanda',
    'nicaragua': 'Nikaragua',
    'niger': 'Nijer',
    'nigeria': 'Nijerya',
    'north macedonia': 'Kuzey Makedonya',
    'northern ireland': 'Kuzey İrlanda',
    'norway': 'Norveç',
    'oman': 'Umman',
    'pakistan': 'Pakistan',
    'palestine': 'Filistin',
    'panama': 'Panama',
    'papua new guinea': 'Papua Yeni Gine',
    'paraguay': 'Paraguay',
    'peru': 'Peru',
    'philippines': 'Filipinler',
    'poland': 'Polonya',
    'portugal': 'Portekiz',
    'qatar': 'Katar',
    'romania': 'Romanya',
    'russia': 'Rusya',
    'rwanda': 'Ruanda',
    'san marino': 'San Marino',
    'saudi arabia': 'Suudi Arabistan',
    'scotland': 'İskoçya',
    'senegal': 'Senegal',
    'serbia': 'Sırbistan',
    'seychelles': 'Seyşeller',
    'sierra leone': 'Sierra Leone',
    'slovakia': 'Slovakya',
    'slovenia': 'Slovenya',
    'somalia': 'Somali',
    'south africa': 'Güney Afrika',
    'south korea': 'Güney Kore',
    'south sudan': 'Güney Sudan',
    'spain': 'İspanya',
    'sudan': 'Sudan',
    'suriname': 'Surinam',
    'sweden': 'İsveç',
    'switzerland': 'İsviçre',
    'syria': 'Suriye',
    'tanzania': 'Tanzanya',
    'thailand': 'Tayland',
    'togo': 'Togo',
    'trinidad and tobago': 'Trinidad ve Tobago',
    'tunisia': 'Tunus',
    'turkey': 'Türkiye',
    'uae': 'Birleşik Arap Emirlikleri',
    'uganda': 'Uganda',
    'ukraine': 'Ukrayna',
    'united arab emirates': 'Birleşik Arap Emirlikleri',
    'united states': 'Amerika Birleşik Devletleri',
    'uruguay': 'Uruguay',
    'usa': 'Amerika Birleşik Devletleri',
    'uzbekistan': 'Özbekistan',
    'venezuela': 'Venezuela',
    'vietnam': 'Vietnam',
    'wales': 'Galler',
    'yemen': 'Yemen',
    'zambia': 'Zambiya',
    'zimbabwe': 'Zimbabwe',
  };
  return map[raw.toLowerCase()] ?? raw;
}

// ─── Match display item ───────────────────────────────────────────────────────

class _MatchDisplay {
  final String teams;
  final String league;
  final String time;

  const _MatchDisplay({required this.teams, this.league = '', this.time = ''});

  /// "Dünya Kupası • 26 Haz 02:00"
  String get sublabel {
    final parts = [league, time].where((s) => s.isNotEmpty);
    return parts.join(' • ');
  }
}

enum _AddStep { search, market, period, line, option }

class _Selection {
  final String teams;
  final String betType;
  const _Selection(this.teams, this.betType);

  bool matches(_Selection other) =>
      teams == other.teams && betType == other.betType;
}

class AddCouponSheet extends StatefulWidget {
  final Coupon? initialCoupon;
  const AddCouponSheet({super.key, this.initialCoupon});

  @override
  State<AddCouponSheet> createState() => _AddCouponSheetState();
}

class _AddCouponSheetState extends State<AddCouponSheet> {
  bool _aiLoading = false;
  final titleController = TextEditingController();
  final siteController = TextEditingController();
  final stakeController = TextEditingController();
  final oddsController = TextEditingController();
  final searchController = TextEditingController();

  final List<_Selection> selections = [];

  bool isAdding = false;
  _AddStep addStep = _AddStep.search;
  String searchQuery = '';
  String? pendingMatch;
  _Market? pendingMarket;
  String? pendingLine;
  int? _editingIndex;

  // ── API search state ──────────────────────────────────────────────────────
  List<_MatchDisplay> _apiResults = [];
  _SearchState _searchState = _SearchState.idle;
  Timer? _searchDebounce;

  bool get _isApiLoading => _searchState == _SearchState.loading;

  // ── toast state ───────────────────────────────────────────────────────────
  bool _showToast = false;
  Timer? _toastTimer;

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    stakeController.addListener(_onFieldChanged);
    oddsController.addListener(_onFieldChanged);
    if (widget.initialCoupon != null) {
      _populateFromCoupon(widget.initialCoupon!);
    }
  }

  void _populateFromCoupon(Coupon c) {
    titleController.text = c.title;
    final metaParts = c.meta.split(' · ');
    if (metaParts.isNotEmpty) siteController.text = metaParts[0];
    stakeController.text = c.stake
        .replaceAll('₺', '')
        .replaceAll(' bahis', '')
        .trim();
    final oddsMatch = RegExp(r'×(.+)$').firstMatch(c.meta);
    if (oddsMatch != null) oddsController.text = oddsMatch.group(1)!.trim();
    for (final m in c.matches) {
      if (m.teams != 'Maç seçilmedi') {
        selections.add(_Selection(m.teams, m.selection));
      }
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _toastTimer?.cancel();
    titleController.dispose();
    siteController.dispose();
    stakeController.dispose();
    oddsController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ── computed ──────────────────────────────────────────────────────────────

  double _parseNum(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;
  double get _odds => _parseNum(oddsController.text);
  double get _stake => _parseNum(stakeController.text);

  String get _potentialText {
    if (_stake <= 0 || _odds <= 0) return '–';
    final result = _stake * _odds;
    final formatted = result == result.truncateToDouble()
        ? result.toInt().toString()
        : result.toStringAsFixed(2);
    return '₺$formatted';
  }

  String get _oddsDisplay {
    if (_odds <= 0) return '–';
    return _odds % 1 == 0 ? _odds.toInt().toString() : _odds.toStringAsFixed(2);
  }

  // ── toast ─────────────────────────────────────────────────────────────────

  void _showDuplicateToast() {
    _toastTimer?.cancel();
    setState(() => _showToast = true);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showToast = false);
    });
  }

  // ── flow control ──────────────────────────────────────────────────────────

  void _openAddFlow() {
    setState(() {
      isAdding = true;
      addStep = _AddStep.search;
      searchQuery = '';
      pendingMatch = null;
      pendingMarket = null;
      pendingLine = null;
      _editingIndex = null;
      _apiResults = [];
      _searchState = _SearchState.idle;
      searchController.clear();
    });
    // Pre-load upcoming matches on open.
    _doSearch('');
  }

  void _openEditFlow(int index) {
    setState(() {
      isAdding = true;
      addStep = _AddStep.market;
      pendingMatch = selections[index].teams;
      pendingMarket = null;
      pendingLine = null;
      _editingIndex = index;
      searchQuery = '';
      searchController.clear();
    });
  }

  void _cancelAddFlow() {
    _searchDebounce?.cancel();
    setState(() {
      isAdding = false;
      searchQuery = '';
      pendingMatch = null;
      pendingMarket = null;
      pendingLine = null;
      _editingIndex = null;
      _apiResults = [];
      _searchState = _SearchState.idle;
      searchController.clear();
    });
  }

  void _selectMatch(String match) {
    setState(() {
      pendingMatch = match;
      addStep = _AddStep.market;
    });
  }

  void _goBack() {
    setState(() {
      switch (addStep) {
        case _AddStep.search:
          break;
        case _AddStep.market:
          addStep = _AddStep.search;
          pendingMatch = null;
          break;
        case _AddStep.period:
          addStep = _AddStep.market;
          pendingMarket = null;
          break;
        case _AddStep.line:
          final iyVariant = pendingMarket != null
              ? _findIyVariant(pendingMarket!)
              : null;
          final hasIy =
              iyVariant != null ||
              (pendingMarket?.name.startsWith('İlk Yarı') ?? false);
          if (hasIy) {
            addStep = _AddStep.period;
          } else {
            addStep = _AddStep.market;
          }
          pendingLine = null;
          break;
        case _AddStep.option:
          if (pendingMarket?.hasLines ?? false) {
            addStep = _AddStep.line;
          } else {
            final iyVariant = pendingMarket != null
                ? _findIyVariant(pendingMarket!)
                : null;
            final hasIy =
                iyVariant != null ||
                (pendingMarket?.name.startsWith('İlk Yarı') ?? false);
            addStep = hasIy ? _AddStep.period : _AddStep.market;
          }
          break;
      }
    });
  }

  void _selectMarket(_Market market) {
    final iyVariant = _findIyVariant(market);
    setState(() {
      pendingMarket = market;
      pendingLine = null;
      if (iyVariant != null) {
        addStep = _AddStep.period;
      } else {
        addStep = market.hasLines ? _AddStep.line : _AddStep.option;
      }
    });
  }

  void _selectPeriod(bool isFirstHalf) {
    final base = pendingMarket!;
    final market = isFirstHalf ? (_findIyVariant(base) ?? base) : base;
    setState(() {
      pendingMarket = market;
      addStep = market.hasLines ? _AddStep.line : _AddStep.option;
    });
  }

  void _selectLine(String line) {
    setState(() {
      pendingLine = line;
      addStep = _AddStep.option;
    });
  }

  void _selectOption(String option) {
    final betText = pendingMarket!.buildBetText(option, pendingLine);
    final newSel = _Selection(pendingMatch!, betText);

    final isDuplicate = selections.asMap().entries.any((e) {
      if (_editingIndex != null && e.key == _editingIndex) return false;
      return e.value.matches(newSel);
    });

    if (isDuplicate) {
      _showDuplicateToast();
      return;
    }

    setState(() {
      if (_editingIndex != null) {
        selections[_editingIndex!] = newSel;
      } else {
        selections.add(newSel);
      }
      isAdding = false;
      _editingIndex = null;
      pendingMatch = null;
      pendingMarket = null;
      pendingLine = null;
      searchQuery = '';
      searchController.clear();
    });
  }

  void _removeSelection(int index) {
    setState(() => selections.removeAt(index));
  }

  Future<void> _clearAllSelections() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t.clearSelectionsDialogTitle,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          t.clearSelectionsDialogBody,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              t.giveUpLabel,
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
    if (confirmed == true) setState(() => selections.clear());
  }

  // ── save ──────────────────────────────────────────────────────────────────

  Future<void> _analyzeWithAI() async {
    final t = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _aiLoading = true);
    try {
      final result = await AiCouponService.instance.analyzeCouponImage(
        File(picked.path),
      );
      if (result == null) {
        if (mounted)
          CouponShare.showTopToast(context, t.couponReadFailedToast);
        return;
      }

      if (result.site != null) siteController.text = result.site!;
      if (result.stake != null) stakeController.text = result.stake!;
      if (result.totalOdds != null) oddsController.text = result.totalOdds!;

      setState(() {
        selections.clear();
        for (final m in result.matchedMatches) {
          selections.add(_Selection(m.matched!, m.selection));
        }
      });

      if (result.unmatchedMatches.isNotEmpty) {
        final names = result.unmatchedMatches.map((m) => m.original).join(', ');
        if (mounted) CouponShare.showTopToast(context, t.notFoundToast(names));
      }

      if (result.matchedMatches.isEmpty) {
        if (mounted)
          CouponShare.showTopToast(
            context,
            t.noMatchMatchedToast,
          );
      }
    } catch (e) {
      if (mounted) CouponShare.showTopToast(context, t.genericErrorToast('$e'));
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  bool _saving = false;

  Future<void> _saveCoupon() async {
    final t = AppLocalizations.of(context)!;
    if (_saving) return;
    if (selections.isEmpty) {
      CouponShare.showTopToast(context, t.addAtLeastOneSelection);
      return;
    }
    if (oddsController.text.trim().isEmpty ||
        _parseNum(oddsController.text) <= 0) {
      CouponShare.showTopToast(context, t.enterValidOdds);
      return;
    }
    if (stakeController.text.trim().isEmpty ||
        _parseNum(stakeController.text) <= 0) {
      CouponShare.showTopToast(context, t.enterStakeAmount);
      return;
    }
    final autoTitle = selections.isNotEmpty
        ? '${selections.length} Seçim ×${oddsController.text.trim().isEmpty ? "?" : oddsController.text.trim()}'
        : 'Yeni Kupon';
    final title = titleController.text.trim().isEmpty
        ? autoTitle
        : titleController.text.trim();
    final site = siteController.text.trim().isEmpty
        ? 'Manuel'
        : siteController.text.trim();
    final stake = stakeController.text.trim().isEmpty
        ? '₺0 bahis'
        : '₺${stakeController.text.trim()} bahis';
    final odds = oddsController.text.trim().isEmpty
        ? '1.00'
        : oddsController.text.trim();
    final potentialRaw = _potentialText;
    final potential = potentialRaw == '–'
        ? 'Bekliyor'
        : '$potentialRaw beklenti';

    final matches = selections.isNotEmpty
        ? selections
              .map(
                (s) => MatchItem(
                  teams: s.teams,
                  selection: s.betType,
                  score: '–:–',
                  minute: '-',
                  status: CouponStatus.pending,
                ),
              )
              .toList()
        : [
            const MatchItem(
              teams: 'Maç seçilmedi',
              selection: 'Bekliyor',
              score: '–:–',
              minute: '-',
              status: CouponStatus.pending,
            ),
          ];

    final newCoupon = Coupon(
      title: selections.isEmpty ? 'Maç seçilmedi' : title,
      meta: '$site · ${matches.length} seçim · ×$odds',
      status: CouponStatus.pending,
      stake: stake,
      potential: potential,
      progress: List.filled(matches.length, CouponStatus.pending),
      matches: matches,
    );

    setState(() => _saving = true);
    final savedCoupon = await CouponStorageService.instance.saveCoupon(
      newCoupon,
    );
    if (!mounted) return;
    Navigator.pop(context, savedCoupon ?? newCoupon);
  }

  // ── search ────────────────────────────────────────────────────────────────

  void _doSearch(String q) {
    final langCode = Localizations.localeOf(context).languageCode;
    _searchDebounce?.cancel();
    setState(() => _searchState = _SearchState.loading);
    final delay = q.trim().isEmpty
        ? Duration.zero
        : const Duration(milliseconds: 350);
    _searchDebounce = Timer(delay, () async {
      try {
        if (q.trim().isEmpty) {
          // Boş arama: canlı + yaklaşan maçları getir
          final liveMatches = await MatchSearchService.instance
              .getLiveMatches();
          if (!mounted) return;
          final filtered = liveMatches
              .where((m) => m.home.isNotEmpty && m.away.isNotEmpty)
              .toList();
          setState(() {
            _apiResults = filtered.map((m) {
              final statusLabel = m.isLive
                  ? '🔴 Canlı ${m.minute}'
                  : m.isPost
                  ? 'Bitti'
                  : '';
              return _MatchDisplay(
                teams: '${m.home} – ${m.away}',
                league: statusLabel,
                time: m.isLive || m.isPost
                    ? '${m.homeScore} - ${m.awayScore}'
                    : '',
              );
            }).toList();
            _searchState = _SearchState.success;
          });
        } else {
          // Yazılı arama: VPS search endpoint
          final results = await MatchSearchService.instance.search(q.trim());
          if (!mounted) return;
          // Eğer VPS'ten sonuç gelmediyse canlı maçlarda filtrele
          if (results.isEmpty) {
            final liveMatches = await MatchSearchService.instance
                .getLiveMatches();
            final ql = q.toLowerCase();
            final filtered = liveMatches
                .where(
                  (m) =>
                      m.home.toLowerCase().contains(ql) ||
                      m.away.toLowerCase().contains(ql),
                )
                .toList();
            setState(() {
              _apiResults = filtered
                  .map(
                    (m) => _MatchDisplay(
                      teams: '${m.home} – ${m.away}',
                      league: m.isLive ? '🔴 Canlı' : '',
                      time: m.isLive || m.isPost
                          ? '${m.homeScore} - ${m.awayScore}'
                          : '',
                    ),
                  )
                  .toList();
              _searchState = _SearchState.success;
            });
          } else {
            setState(() {
              _apiResults = results
                  .map(
                    (r) => _MatchDisplay(
                      teams: '${_trTeam(r.home, langCode)} – ${_trTeam(r.away, langCode)}',
                      league: _trLeague(r.league, langCode),
                      time: _trDate(r.time, langCode),
                    ),
                  )
                  .toList();
              _searchState = _SearchState.success;
            });
          }
        }
      } catch (e) {
        debugPrint('[MatchSearch] error: $e');
        if (!mounted) return;
        setState(() {
          _apiResults = [];
          _searchState = _SearchState.error;
        });
      }
    });
  }

  /// Returns items to display in the search list.
  /// - loading/idle → empty (spinner shown)
  /// - success      → API results (may be empty → "Maç bulunamadı")
  /// - error        → mock fallback filtered by current query
  List<String> get _recentTeams =>
      selections.isEmpty ? [] : [selections.last.teams];

  List<_MatchDisplay> get _displayMatches {
    switch (_searchState) {
      case _SearchState.idle:
      case _SearchState.loading:
        return [];
      case _SearchState.success:
        return _sortMatches(
          _apiResults,
          _recentTeams,
        ); // caller shows "Maç bulunamadı" when empty
      case _SearchState.error:
        const maxResults = 6;
        if (searchQuery.isEmpty) {
          return _mockMatches
              .take(maxResults)
              .map((m) => _MatchDisplay(teams: m))
              .toList();
        }
        final q = searchQuery.toLowerCase();
        return _mockMatches
            .where((m) => m.toLowerCase().contains(q))
            .take(maxResults)
            .map((m) => _MatchDisplay(teams: m))
            .toList();
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final sheetContent = Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.addCouponTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: _analyzeWithAI,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _aiLoading
                        ? const SizedBox(
                            width: 60,
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t.aiAddButton,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              t.addCouponSubtitle,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Fields
            MatchlyInput(
              controller: titleController,
              label: t.couponNameLabel,
              hint: t.couponNameHint,
            ),
            const SizedBox(height: 10),
            _LeagueSelector(
              selected: siteController.text,
              onSelected: (v) => setState(() => siteController.text = v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: MatchlyInput(
                    controller: stakeController,
                    label: t.stakeAmountLabel,
                    hint: '120',
                    prefix: '₺',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MatchlyInput(
                    controller: oddsController,
                    label: t.oddsFieldLabel,
                    hint: '4.20',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selection list
            if (selections.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    t.selectionsCountLabel(selections.length),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearAllSelections,
                    child: Text(
                      t.clearAllSelections,
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(selections.length, (i) {
                final s = selections[i];
                final isEditing = _editingIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isEditing
                            ? AppColors.brand.withOpacity(0.4)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${s.teams} · ${s.betType}',
                            style: TextStyle(
                              color: isEditing
                                  ? AppColors.brand
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openEditFlow(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: AppColors.brand,
                              size: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeSelection(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: AppColors.red,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
            ],

            // Add/edit panel
            if (isAdding)
              _AddSelectionPanel(
                step: addStep,
                isEditing: _editingIndex != null,
                searchController: searchController,
                matchResults: _displayMatches,
                isSearchLoading: _isApiLoading,
                apiSucceeded: _searchState == _SearchState.success,
                pendingMatch: pendingMatch,
                pendingMarket: pendingMarket,
                pendingLine: pendingLine,
                onSearchChanged: (v) {
                  setState(() => searchQuery = v);
                  _doSearch(v);
                },
                onMatchSelected: _selectMatch,
                onMarketSelected: _selectMarket,
                onPeriodSelected: _selectPeriod,
                onLineSelected: _selectLine,
                onOptionSelected: _selectOption,
                onCancel: _cancelAddFlow,
                onBack: _goBack,
              )
            else
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _openAddFlow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: BorderSide(color: AppColors.green.withOpacity(0.25)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    t.addSelectionButton,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Premium summary card
            _CouponSummaryCard(
              selections: selections,
              oddsDisplay: _oddsDisplay,
              potentialText: _potentialText,
            ),

            const SizedBox(height: 14),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.green.withOpacity(0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        t.saveLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        sheetContent,
        // Floating top toast
        Positioned(
          top: 52,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showToast ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: AnimatedSlide(
                offset: _showToast ? Offset.zero : const Offset(0, -0.3),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        t.duplicateSelectionToast,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Premium coupon summary card ──────────────────────────────────────────────

class _CouponSummaryCard extends StatelessWidget {
  final List<_Selection> selections;
  final String oddsDisplay;
  final String potentialText;

  const _CouponSummaryCard({
    required this.selections,
    required this.oddsDisplay,
    required this.potentialText,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Text(
                  t.couponSummaryTitle,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                if (selections.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t.selectionsCountChip(selections.length),
                      style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.gray),

          // Empty state
          if (selections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.textTertiary.withOpacity(0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.noSelectionYet,
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Selection rows
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: List.generate(selections.length, (i) {
                  final s = selections[i];
                  final isLast = i == selections.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.teams,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    s.betType,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brand.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: AppColors.brand,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) Container(height: 1, color: AppColors.gray),
                    ],
                  );
                }),
              ),
            ),

            // Totals footer
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  // Oran
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.oranLabel,
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          oddsDisplay,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.gray),
                  const SizedBox(width: 14),
                  // Beklenti
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.beklentiLabel,
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          potentialText == '–'
                              ? '–'
                              : '$potentialText beklenti',
                          style: TextStyle(
                            color: potentialText == '–'
                                ? AppColors.textTertiary
                                : AppColors.green,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Add selection panel ──────────────────────────────────────────────────────

class _AddSelectionPanel extends StatelessWidget {
  final _AddStep step;
  final bool isEditing;
  final TextEditingController searchController;
  final List<_MatchDisplay> matchResults;
  final bool isSearchLoading;
  final bool apiSucceeded;
  final String? pendingMatch;
  final _Market? pendingMarket;
  final String? pendingLine;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onMatchSelected;
  final ValueChanged<_Market> onMarketSelected;
  final ValueChanged<bool> onPeriodSelected;
  final VoidCallback onBack;
  final ValueChanged<String> onLineSelected;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onCancel;

  const _AddSelectionPanel({
    required this.step,
    required this.isEditing,
    required this.searchController,
    required this.matchResults,
    required this.isSearchLoading,
    required this.apiSucceeded,
    required this.pendingMatch,
    required this.pendingMarket,
    required this.pendingLine,
    required this.onSearchChanged,
    required this.onMatchSelected,
    required this.onMarketSelected,
    required this.onPeriodSelected,
    required this.onBack,
    required this.onLineSelected,
    required this.onOptionSelected,
    required this.onCancel,
  });

  String _title(AppLocalizations t) {
    if (isEditing) {
      switch (step) {
        case _AddStep.search:
          return t.selectMatchTitle;
        case _AddStep.market:
          return t.editMarketTitle;
        case _AddStep.period:
          return t.editTimeTitle;
        case _AddStep.line:
          return t.editLineTitle;
        case _AddStep.option:
          return t.editOptionTitle;
      }
    }
    switch (step) {
      case _AddStep.search:
        return t.selectMatchTitle;
      case _AddStep.market:
        return t.marketTitle;
      case _AddStep.period:
        return t.timeTitle;
      case _AddStep.line:
        return t.lineTitle;
      case _AddStep.option:
        return t.optionTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditing
              ? AppColors.brand.withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                if (step != _AddStep.search) ...[
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBack,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textTertiary,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  _title(t),
                  style: TextStyle(
                    color: isEditing
                        ? AppColors.brand
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onCancel,
                  child: Icon(
                    Icons.close,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          if (step != _AddStep.search) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (pendingMatch != null) _Chip(label: pendingMatch!),
                  if (pendingMarket != null && step != _AddStep.market)
                    _Chip(label: pendingMarket!.name),
                  if (pendingLine != null) _Chip(label: pendingLine!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (step == _AddStep.search)
            _SearchBody(
              searchController: searchController,
              matchResults: matchResults,
              isLoading: isSearchLoading,
              apiSucceeded: apiSucceeded,
              onSearchChanged: onSearchChanged,
              onMatchSelected: onMatchSelected,
            )
          else if (step == _AddStep.market)
            _MarketGroupBody(onMarketSelected: onMarketSelected)
          else if (step == _AddStep.period)
            _PeriodBody(onSelected: onPeriodSelected)
          else if (step == _AddStep.line)
            _ButtonsBody(
              items: pendingMarket!.lines!,
              onSelected: onLineSelected,
            )
          else
            _ButtonsBody(
              items: pendingMarket!.options,
              onSelected: onOptionSelected,
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Shared premium tap animation ──────────────────────────────────────────────
//
// Basılıyken hafif küçülür; bırakılınca kısa bir "spring" ile hafif büyüyüp
// rengini vurgular, sonra onTap tetiklenir. Kupon ekleme akışındaki tüm
// seçim adımlarında (market, dönem, seçenek/çizgi, maç arama) aynı his için
// kullanılır.
class _TapPulse extends StatefulWidget {
  final VoidCallback onTap;
  final Widget Function(BuildContext context, bool confirmed) builder;
  final HitTestBehavior? behavior;
  const _TapPulse({required this.onTap, required this.builder, this.behavior});

  @override
  State<_TapPulse> createState() => _TapPulseState();
}

class _TapPulseState extends State<_TapPulse> {
  bool _pressed = false;
  bool _confirmed = false;

  void _handleTap() {
    setState(() => _confirmed = true);
    Future.delayed(const Duration(milliseconds: 150), widget.onTap);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _confirmed ? 1.07 : (_pressed ? 0.95 : 1.0),
        duration: Duration(milliseconds: _confirmed ? 260 : 100),
        curve: _confirmed ? Curves.easeOutBack : Curves.easeOut,
        child: widget.builder(context, _confirmed),
      ),
    );
  }
}

// ─── Period (match / first half) body ─────────────────────────────────────────

class _PeriodBody extends StatelessWidget {
  final ValueChanged<bool> onSelected;
  const _PeriodBody({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: _PeriodOption(
              label: t.matchEndLabel,
              icon: Icons.sports_soccer_rounded,
              onTap: () => onSelected(false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PeriodOption(
              label: t.firstHalfLabel,
              icon: Icons.schedule_rounded,
              onTap: () => onSelected(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodOption extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PeriodOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PeriodOption> createState() => _PeriodOptionState();
}

class _PeriodOptionState extends State<_PeriodOption> {
  @override
  Widget build(BuildContext context) {
    return _TapPulse(
      onTap: widget.onTap,
      builder: (context, confirmed) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: confirmed
              ? AppColors.brand.withOpacity(0.16)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: confirmed ? AppColors.brand : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Column(
          children: [
            Icon(widget.icon, size: 20, color: AppColors.brand),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: TextStyle(
                color: confirmed ? AppColors.brand : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Market group body ────────────────────────────────────────────────────────

IconData _marketIcon(String name) {
  if (name.contains('Maç Sonucu')) return Icons.flag_rounded;
  if (name.contains('Sonucu')) return Icons.schedule_rounded;
  if (name.contains('KG')) return Icons.swap_horiz_rounded;
  if (name.contains('Korner')) return Icons.turn_right_rounded;
  if (name.contains('Kart')) return Icons.square_rounded;
  if (name.contains('Alt') || name.contains('Üst'))
    return Icons.unfold_more_rounded;
  return Icons.sports_soccer_rounded;
}

/// Base (maç sonu) market'in adına göre eşleşen İlk Yarı market'ini bulur.
_Market? _findIyVariant(_Market base) {
  final iyName = base.name == 'Maç Sonucu'
      ? 'İlk Yarı Sonucu'
      : 'İlk Yarı $base.name';
  try {
    return _markets.firstWhere((m) => m.name == iyName);
  } catch (_) {
    return null;
  }
}

/// Sadece "maç sonu" market'lerini döndürür (İY varyantları ayrı entry olarak gösterilmez,
/// ana market'e dokununca sekme ile erişilir).
final _baseMarkets = _markets
    .where((m) => !m.name.startsWith('İlk Yarı'))
    .toList();

class _MarketGroupBody extends StatelessWidget {
  final ValueChanged<_Market> onMarketSelected;
  const _MarketGroupBody({required this.onMarketSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
        ),
        itemCount: _baseMarkets.length,
        itemBuilder: (context, index) {
          final market = _baseMarkets[index];
          return _MarketTile(
            market: market,
            onTap: () => onMarketSelected(market),
          );
        },
      ),
    );
  }
}

class _MarketTile extends StatefulWidget {
  final _Market market;
  final VoidCallback onTap;
  const _MarketTile({required this.market, required this.onTap});

  @override
  State<_MarketTile> createState() => _MarketTileState();
}

class _MarketTileState extends State<_MarketTile> {
  @override
  Widget build(BuildContext context) {
    return _TapPulse(
      onTap: widget.onTap,
      builder: (context, confirmed) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: confirmed
              ? AppColors.brand.withOpacity(0.16)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: confirmed ? AppColors.brand : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _marketIcon(widget.market.name),
              size: 17,
              color: AppColors.brand,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.market.name,
                style: TextStyle(
                  color: confirmed ? AppColors.brand : AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search body ─────────────────────────────────────────────────────────────

class _SearchBody extends StatelessWidget {
  final TextEditingController searchController;
  final List<_MatchDisplay> matchResults;
  final bool isLoading;
  final bool apiSucceeded;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onMatchSelected;

  const _SearchBody({
    required this.searchController,
    required this.matchResults,
    required this.isLoading,
    required this.apiSucceeded,
    required this.onSearchChanged,
    required this.onMatchSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search field ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextField(
            controller: searchController,
            autofocus: true,
            onChanged: onSearchChanged,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: t.searchTeamOrLeagueHint,
              hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textTertiary,
                size: 18,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.brand),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            t.searchTeamOrLeagueHint,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ),
        const SizedBox(height: 4),

        // ── Results ───────────────────────────────────────────────────────
        if (isLoading)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brand,
                ),
              ),
            ),
          )
        else if (matchResults.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Text(
              apiSucceeded ? t.noMatchFound : t.noResultFound,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          )
        else
          // Cap height at ~4.5 items; scroll if more.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              itemCount: matchResults.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: Colors.white.withOpacity(0.05),
              ),
              itemBuilder: (_, i) {
                final m = matchResults[i];
                return _AnimatedMatchRow(
                  match: m,
                  onTap: () => onMatchSelected(m.teams),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AnimatedMatchRow extends StatefulWidget {
  final _MatchDisplay match;
  final VoidCallback onTap;
  const _AnimatedMatchRow({required this.match, required this.onTap});

  @override
  State<_AnimatedMatchRow> createState() => _AnimatedMatchRowState();
}

class _AnimatedMatchRowState extends State<_AnimatedMatchRow> {
  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return _TapPulse(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      builder: (context, confirmed) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: confirmed
            ? AppColors.brand.withOpacity(0.14)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.teams,
              style: TextStyle(
                color: confirmed ? AppColors.brand : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (m.sublabel.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                m.sublabel,
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Button grid body ─────────────────────────────────────────────────────────

class _ButtonsBody extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onSelected;
  const _ButtonsBody({required this.items, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map(
              (item) => _AnimatedChipButton(
                label: item,
                onTap: () => onSelected(item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AnimatedChipButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _AnimatedChipButton({required this.label, required this.onTap});

  @override
  State<_AnimatedChipButton> createState() => _AnimatedChipButtonState();
}

class _AnimatedChipButtonState extends State<_AnimatedChipButton> {
  @override
  Widget build(BuildContext context) {
    return _TapPulse(
      onTap: widget.onTap,
      builder: (context, confirmed) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: confirmed
              ? AppColors.brand.withOpacity(0.18)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: confirmed ? AppColors.brand : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: confirmed ? AppColors.brand : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Context chip ─────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brand.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.brand,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── League picker sheet (with search) ───────────────────────────────────────

class _LeaguePickerSheet extends StatefulWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _LeaguePickerSheet({required this.selected, required this.onSelected});

  @override
  State<_LeaguePickerSheet> createState() => _LeaguePickerSheetState();
}

class _LeaguePickerSheetState extends State<_LeaguePickerSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = _leagues;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.trim().isEmpty
          ? _leagues
          : _leagues
                .where((l) => l.toLowerCase().contains(q.toLowerCase()))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) => SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.leagueSelectTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                onChanged: _onSearch,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: t.leagueSearchHint,
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.green.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        t.leagueNotFound,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final league = _filtered[i];
                        final isSelected = league == widget.selected;
                        return GestureDetector(
                          onTap: () {
                            widget.onSelected(league);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.green.withOpacity(0.10)
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.green.withOpacity(0.35)
                                    : Colors.white.withOpacity(0.07),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    league,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.green
                                          : AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_rounded,
                                    color: AppColors.green,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── League selector ─────────────────────────────────────────────────────────

class _LeagueSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _LeagueSelector({required this.selected, required this.onSelected});

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          _LeaguePickerSheet(selected: selected, onSelected: onSelected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected.isEmpty
                ? Colors.white.withOpacity(0.08)
                : AppColors.brand.withOpacity(0.30),
            width: selected.isEmpty ? 1 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected.isEmpty ? t.selectLeaguePlaceholder : selected,
                style: TextStyle(
                  color: selected.isEmpty
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: selected.isEmpty
                  ? AppColors.textTertiary
                  : AppColors.brand,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Text input ───────────────────────────────────────────────────────────────

class MatchlyInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? prefix;

  const MatchlyInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 15),
            prefixText: prefix,
            prefixStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 8),
            filled: false,
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2a2a2e), width: 0.5),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2a2a2e), width: 0.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.green.withOpacity(0.6),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
