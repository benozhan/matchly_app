import 'package:flutter/material.dart';
import 'daily_history_page.dart';

import '../../core/app_colors.dart';
import '../../models/coupon.dart';
import '../home/status_badge.dart';

class IstatistikPage extends StatefulWidget {
  final List<Coupon> allCoupons;

  const IstatistikPage({super.key, required this.allCoupons});

  @override
  State<IstatistikPage> createState() => _IstatistikPageState();
}

class _IstatistikPageState extends State<IstatistikPage> {
  String _selectedLig = 'Tümü';

  List<Coupon> get _filtered {
    if (_selectedLig == 'Tümü') return widget.allCoupons;
    final key = _selectedLig.toLowerCase();
    return widget.allCoupons.where((c) {
      final lig = c.meta.split('·').first.trim().toLowerCase();
      return lig == key;
    }).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static double _parseAmount(String s) {
    final m = RegExp(r'₺([\d]+(?:[.,]\d+)?)').firstMatch(s);
    if (m == null) return 0;
    return double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
  }

  static String _fmt(double n) {
    final neg = n < 0;
    final abs = n.abs();
    final i = abs.toInt();
    String formatted;
    if (i >= 1000) {
      formatted = '₺${(i ~/ 1000)}.${(i % 1000).toString().padLeft(3, "0")}';
    } else {
      formatted = '₺$i';
    }
    if (i == 0) return '–';
    return neg ? '-$formatted' : formatted;
  }

  static BoxDecoration _cardDeco() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.border, width: 0.5),
    boxShadow: [
      BoxShadow(
        color: AppColors.border,
        blurRadius: 24,
        offset: const Offset(0, 10),
        spreadRadius: -4,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final allCoupons = _filtered;
    final total = allCoupons.length;
    final kazanan = allCoupons
        .where((c) => c.status == CouponStatus.winning)
        .length;
    final kaybeden = allCoupons
        .where((c) => c.status == CouponStatus.risk)
        .length;
    final iptal = allCoupons
        .where((c) => c.status == CouponStatus.cancelled)
        .length;
    final aktif = allCoupons
        .where((c) => c.status == CouponStatus.pending)
        .length;
    final resolved = kazanan + kaybeden;
    final basari = resolved > 0 ? (kazanan / resolved * 100).round() : 0;

    final recent = allCoupons
        .where((c) => c.status != CouponStatus.pending)
        .take(5)
        .toList();

    // Site bazlı istatistik (kupon eklerken girilen bahis sitesi adına göre
    // gruplanır). Büyük/küçük harf farkını yok sayıp ilk görülen yazımı
    // gösterim için kullanıyoruz, ör. "Yasalbahis" ve "yasalbahis" tek
    // satırda birleşsin.
    final ligStats = <String, Map<String, dynamic>>{};
    final ligDisplay = <String, String>{};
    for (final c in allCoupons) {
      final ligRaw = c.meta.split('·').first.trim().isEmpty
          ? 'Diğer'
          : c.meta.split('·').first.trim();
      final lig = ligRaw.toLowerCase();
      ligDisplay.putIfAbsent(lig, () => ligRaw);
      ligStats.putIfAbsent(
        lig,
        () => {
          'kupon': 0,
          'kazanan': 0,
          'kaybeden': 0,
          'bahis': 0.0,
          'kazanc': 0.0,
        },
      );
      ligStats[lig]!['kupon'] = (ligStats[lig]!['kupon'] as int) + 1;
      if (c.status == CouponStatus.winning) {
        ligStats[lig]!['kazanan'] = (ligStats[lig]!['kazanan'] as int) + 1;
        ligStats[lig]!['kazanc'] =
            (ligStats[lig]!['kazanc'] as double) +
            _parseAmount(c.potential) -
            _parseAmount(c.stake);
      }
      if (c.status == CouponStatus.risk) {
        ligStats[lig]!['kaybeden'] = (ligStats[lig]!['kaybeden'] as int) + 1;
        ligStats[lig]!['kazanc'] =
            (ligStats[lig]!['kazanc'] as double) - _parseAmount(c.stake);
      }
      if (c.status != CouponStatus.pending) {
        ligStats[lig]!['bahis'] =
            (ligStats[lig]!['bahis'] as double) + _parseAmount(c.stake);
      }
    }
    final ligList =
        ligStats.entries
            .map((e) => MapEntry(ligDisplay[e.key]!, e.value))
            .toList()
          ..sort(
            (a, b) =>
                (b.value['kupon'] as int).compareTo(a.value['kupon'] as int),
          );

    // Net kar/zarar
    final toplamKazanc = allCoupons
        .where((c) => c.status == CouponStatus.winning)
        .fold(0.0, (s, c) => s + _parseAmount(c.potential));
    final toplamKayip = allCoupons
        .where((c) => c.status == CouponStatus.risk)
        .fold(0.0, (s, c) => s + _parseAmount(c.stake));
    final netKarZarar = toplamKazanc - toplamKayip;

    // Günlük gruplama
    final Map<String, List<Coupon>> gunlukMap = {};
    for (final c in allCoupons) {
      if (c.createdAt == null) continue;
      final key =
          '${c.createdAt!.year}-${c.createdAt!.month.toString().padLeft(2, '0')}-${c.createdAt!.day.toString().padLeft(2, '0')}';
      gunlukMap.putIfAbsent(key, () => []).add(c);
    }
    final gunlukList = gunlukMap.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        // ── Header ───────────────────────────────────────────────────────────
        Text(
          'İstatistik',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Kupon performans özeti',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // ── Site filtre ───────────────────────────────────────────────────────
        Builder(
          builder: (context) {
            final siteDisplay = <String, String>{};
            for (final c in widget.allCoupons) {
              final raw = c.meta.split('·').first.trim();
              if (raw.isEmpty) continue;
              siteDisplay.putIfAbsent(raw.toLowerCase(), () => raw);
            }
            final ligler = ['Tümü', ...siteDisplay.values.toList()..sort()];
            return SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ligler.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final lig = ligler[i];
                  final selected = _selectedLig == lig;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLig = lig),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.brand : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.brand : AppColors.border,
                        ),
                      ),
                      child: Text(
                        lig,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Empty state ───────────────────────────────────────────────────────
        if (total == 0) ...[
          _EmptyState(),
        ] else ...[
          // ── Top summary — 4 stats ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: _cardDeco(),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _SumStat(
                    value: '$total',
                    label: 'Toplam',
                    color: AppColors.textSecondary,
                  ),
                  _SDivider(),
                  _SumStat(
                    value: '$kazanan',
                    label: 'Kazanan',
                    color: AppColors.green,
                  ),
                  _SDivider(),
                  _SumStat(
                    value: '$kaybeden',
                    label: 'Kaybeden',
                    color: AppColors.red,
                  ),
                  _SDivider(),
                  _SumStat(
                    value: '$basari%',
                    label: 'Başarı',
                    color: const Color(0xFFF0E8DA),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Status breakdown ──────────────────────────────────────────────
          Container(
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Text(
                    'DURUM DAĞILIMI',
                    style: TextStyle(
                      color: AppColors.textTertiary.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Container(height: 0.5, color: AppColors.border),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    children: [
                      _StatusRow(
                        label: 'Kazanan',
                        count: kazanan,
                        color: AppColors.green,
                        total: resolved > 0 ? resolved : 1,
                      ),
                      const SizedBox(height: 10),
                      _StatusRow(
                        label: 'Kaybeden',
                        count: kaybeden,
                        color: AppColors.red,
                        total: resolved > 0 ? resolved : 1,
                      ),
                      const SizedBox(height: 10),
                      _StatusRow(
                        label: 'İptal',
                        count: iptal,
                        color: const Color(0xFF636366),
                        total: total > 0 ? total : 1,
                      ),
                      const SizedBox(height: 10),
                      _StatusRow(
                        label: 'Aktif',
                        count: aktif,
                        color: const Color(0xFF8E8E93),
                        total: total > 0 ? total : 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Net Kar/Zarar ─────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: _cardDeco(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Kar / Zarar',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NetStat(
                        label: 'Toplam Kazanç',
                        value: _fmt(toplamKazanc),
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NetStat(
                        label: 'Toplam Kayıp',
                        value: _fmt(toplamKayip),
                        color: AppColors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NetStat(
                        label: 'Net',
                        value:
                            (netKarZarar >= 0 ? '+' : '') +
                            _fmt(netKarZarar.abs()),
                        color: netKarZarar >= 0
                            ? AppColors.green
                            : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Günlük Geçmiş ─────────────────────────────────────────────────
          if (gunlukList.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DailyHistory(
              gunlukList: gunlukList,
              fmt: _fmt,
              parseAmount: _parseAmount,
            ),
          ],

          // ── Site Bazlı İstatistik ──────────────────────────────────────────
          if (ligList.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Text(
                      'Site Bazlı',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...ligList.map((e) {
                    final lig = e.key;
                    final s = e.value;
                    final kupon = s['kupon'] as int;
                    final kazanan = s['kazanan'] as int;
                    final kaybeden = s['kaybeden'] as int;
                    final bahis = s['bahis'] as double;
                    final kazanc = s['kazanc'] as double;
                    final net = kazanc - bahis;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              lig,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$kupon kupon',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$kazanan ✅  $kaybeden ❌',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                (net >= 0 ? '+' : '') + _fmt(net.abs()),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: net >= 0
                                      ? AppColors.green
                                      : AppColors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],

          if (recent.isNotEmpty) ...[
            const SizedBox(height: 12),

            // ── Recent performance ────────────────────────────────────────
            Container(
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Text(
                      'SON PERFORMANS',
                      style: TextStyle(
                        color: AppColors.textTertiary.withOpacity(0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Container(height: 0.5, color: AppColors.border),
                  ),
                  ...recent.asMap().entries.map((e) {
                    final isLast = e.key == recent.length - 1;
                    return _RecentRow(coupon: e.value, isLast: isLast);
                  }),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// ─── Summary stat cell ────────────────────────────────────────────────────────

class _SumStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SumStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, color: AppColors.border);
}

// ─── Status bar row ───────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final int total;

  const _StatusRow({
    required this.label,
    required this.count,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 4, color: AppColors.border),
                FractionallySizedBox(
                  widthFactor: pct.clamp(0.0, 1.0),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Recent performance row ───────────────────────────────────────────────────

class _RecentRow extends StatelessWidget {
  final Coupon coupon;
  final bool isLast;
  const _RecentRow({required this.coupon, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isWin = coupon.status == CouponStatus.winning;
    final isLoss = coupon.status == CouponStatus.risk;

    IconData icon;
    Color iconColor;
    if (isWin) {
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.green;
    } else if (isLoss) {
      icon = Icons.cancel_rounded;
      iconColor = AppColors.red;
    } else {
      icon = Icons.remove_circle_rounded;
      iconColor = const Color(0xFF636366);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  coupon.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: coupon.status, resolved: true),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(height: 0.5, color: AppColors.border),
          ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📊', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 14),
          Text(
            'Henüz istatistik yok',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kupon ekledikçe burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NetStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Günlük Geçmiş ───────────────────────────────────────────────────────────

class _DailyHistory extends StatelessWidget {
  final List<MapEntry<String, List<Coupon>>> gunlukList;
  final String Function(double) fmt;
  final double Function(String) parseAmount;

  const _DailyHistory({
    required this.gunlukList,
    required this.fmt,
    required this.parseAmount,
  });

  static const _days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final show = gunlukList.take(7).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GÜNLÜK GEÇMİŞ',
                  style: TextStyle(
                    color: AppColors.textTertiary.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Son ${show.length} gün',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(height: 0.5, color: AppColors.border),
          ),
          ...show.map((entry) {
            final dt = DateTime.parse(entry.key);
            final coupons = entry.value;
            final tuttu = coupons
                .where((c) => c.status == CouponStatus.winning)
                .length;
            final yatti = coupons
                .where((c) => c.status == CouponStatus.risk)
                .length;
            final yatirim = coupons.fold(
              0.0,
              (s, c) => s + parseAmount(c.stake),
            );
            final kazanc = coupons
                .where((c) => c.status == CouponStatus.winning)
                .fold(0.0, (s, c) => s + parseAmount(c.potential));
            final netVal = kazanc - yatirim;
            final netColor = netVal > 0
                ? AppColors.green
                : netVal < 0
                ? AppColors.red
                : AppColors.textSecondary;

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: netVal > 0
                          ? AppColors.green
                          : netVal < 0
                          ? AppColors.red
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${dt.day}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                            height: 1,
                          ),
                        ),
                        Text(
                          _days[dt.weekday],
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${coupons.length} kupon',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: AppColors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$tuttu tuttu',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '$yatti yattı',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${netVal >= 0 ? '+' : ''}${fmt(netVal)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: netColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${fmt(yatirim)} yatırım · ${fmt(kazanc)} kazanç',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyHistoryPage(
                    allCoupons: gunlukList.expand((e) => e.value).toList(),
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  'Tüm geçmişi gör →',
                  style: TextStyle(fontSize: 11, color: AppColors.brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
