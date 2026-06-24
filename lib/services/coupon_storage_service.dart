import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coupon.dart';

class CouponStorageService {
  CouponStorageService._();
  static final CouponStorageService instance = CouponStorageService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> saveCoupon(Coupon coupon) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final couponRow = await _client
        .from('coupons')
        .insert({
          'user_id': user.id,
          'title': coupon.title,
          'meta': coupon.meta,
          'status': coupon.status.name,
          'stake': coupon.stake,
          'potential': coupon.potential,
        })
        .select('id')
        .single();

    final couponId = couponRow['id'] as String;

    final rows = coupon.matches.asMap().entries.map((entry) {
      final index = entry.key;
      final match = entry.value;

      return {
        'coupon_id': couponId,
        'teams': match.teams,
        'selection': match.selection,
        'score': match.score,
        'minute': match.minute,
        'status': match.status.name,
        'sort_order': index,
      };
    }).toList();

    if (rows.isNotEmpty) {
      await _client.from('coupon_matches').insert(rows);
    }
  }
}