import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/coupon.dart';

class DailyHistoryPage extends StatelessWidget {
  final List<Coupon> allCoupons;

  const DailyHistoryPage({super.key, required this.allCoupons});

  static String _fmt(double n) {
    final neg = n < 0;
    final abs = n.abs();
    final i = abs.toInt();
    if (i == 0) return '–';
    String f;
    if (i >= 1000) {
      f = '₺${(i ~/ 1000)}.${(i % 1000).toString().padLeft(3, "0")}';
    } else {
      f = '₺$i';
    }
    return neg ? '-$f' : f;
  }

  static double _parseAmount(String s) {
    final m = RegExp(r'[\d.]+').firstMatch(s.replaceAll(',', '.'));
    return double.tryParse(m?.group(0) ?? '0') ?? 0;
  }

  static const _days = ['', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Coupon>> gunlukMap = {};
    for (final c in allCoupons) {
      if (c.createdAt == null) continue;
      final key = '${c.createdAt!.year}-${c.createdAt!.month.toString().padLeft(2, "0")}-${c.createdAt!.day.toString().padLeft(2, "0")}';
      gunlukMap.putIfAbsent(key, () => []).add(c);
    }
    final gunlukList = gunlukMap.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Günlük Geçmiş', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: gunlukList.isEmpty
          ? const Center(child: Text('Henüz geçmiş yok', style: TextStyle(color: AppColors.textTertiary)))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: gunlukList.length,
              itemBuilder: (context, index) {
                final entry = gunlukList[index];
                final dt = DateTime.parse(entry.key);
                final coupons = entry.value;
                final tuttu = coupons.where((c) => c.status == CouponStatus.winning).length;
                final yatti = coupons.where((c) => c.status == CouponStatus.risk).length;
                final aktif = coupons.where((c) => c.status == CouponStatus.pending).length;
                final yatirim = coupons.fold(0.0, (s, c) => s + _parseAmount(c.stake));
                final kazanc = coupons.where((c) => c.status == CouponStatus.winning).fold(0.0, (s, c) => s + _parseAmount(c.potential));
                final netVal = kazanc - yatirim;
                final netColor = netVal > 0 ? AppColors.green : netVal < 0 ? AppColors.red : AppColors.textSecondary;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 72,
                        decoration: BoxDecoration(
                          color: netVal > 0 ? AppColors.green : netVal < 0 ? AppColors.red : AppColors.border,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${dt.day}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1)),
                            Text(_days[dt.weekday], style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    aktif > 0 ? '${coupons.length} kupon · $aktif aktif' : '${coupons.length} kupon',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                                      const SizedBox(width: 3),
                                      Text('$tuttu tuttu', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(width: 8),
                                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle)),
                                      const SizedBox(width: 3),
                                      Text('$yatti yattı', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${netVal >= 0 ? "+" : ""}${_fmt(netVal)}',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: netColor),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_fmt(yatirim)} yatırım · ${_fmt(kazanc)} kazanç',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
