import '../models/coupon.dart';

double _parseAmount(String raw) =>
    double.tryParse(RegExp(r'₺([\d]+)').firstMatch(raw)?.group(1) ?? '0') ?? 0;

/// Kasanın kuponlardan etkilenen kısmını hesaplar. Bahis yatırıldığı ANDA
/// (kupon oluşturulunca, sonuç beklemeden) o tutar kasadan düşmüş sayılır:
/// - bekleyen: -bahis (para kasadan çıktı, henüz sonuç belli değil)
/// - kaybeden: -bahis (bekleyenle aynı — para zaten çıkmıştı, geri gelmedi)
/// - kazanan: +potansiyel - bahis (bahis geri + kazanç eklendi)
/// - iptal/void: 0 (bahis parası iade edildi, kasa etkilenmez)
double calcKasaDelta(List<Coupon> coupons) {
  double delta = 0;
  for (final c in coupons) {
    if (c.status == CouponStatus.cancelled || c.status == CouponStatus.void_) {
      continue;
    }
    final stake = _parseAmount(c.stake);
    if (c.status == CouponStatus.winning) {
      delta += _parseAmount(c.potential) - stake;
    } else {
      delta -= stake;
    }
  }
  return delta;
}
