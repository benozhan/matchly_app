import '../models/coupon.dart';

/// Sonuçlanmış kuponlardan (kazanan: potansiyel - bahis, kaybeden: -bahis)
/// toplam net kâr/zarar hesaplar. Bekleyen kuponlar hesaba katılmaz.
double calcNetProfit(List<Coupon> coupons) {
  double profit = 0;
  for (final c in coupons) {
    final stake =
        double.tryParse(RegExp(r'₺([\d]+)').firstMatch(c.stake)?.group(1) ?? '0') ?? 0;
    if (c.status == CouponStatus.winning) {
      final potential =
          double.tryParse(RegExp(r'₺([\d]+)').firstMatch(c.potential)?.group(1) ?? '0') ?? 0;
      profit += potential - stake;
    } else if (c.status == CouponStatus.risk) {
      profit -= stake;
    }
  }
  return profit;
}
