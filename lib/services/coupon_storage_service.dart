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

  Future<List<Coupon>> loadCoupons() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final couponRows = await _client
        .from('coupons')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final coupons = <Coupon>[];

    for (final row in couponRows) {
      final matchRows = await _client
          .from('coupon_matches')
          .select()
          .eq('coupon_id', row['id'])
          .order('sort_order');

      final matches = matchRows.map<MatchItem>((m) {
        final rawMStatus = m['status'] as String? ?? 'pending';
        final mappedMStatus = rawMStatus == 'lost' ? 'risk'
            : rawMStatus == 'won' ? 'winning'
            : rawMStatus;
        final status = CouponStatus.values.firstWhere(
          (s) => s.name == mappedMStatus,
          orElse: () => CouponStatus.pending,
        );

        return MatchItem(
          teams: m['teams'] as String? ?? '',
          selection: m['selection'] as String? ?? '',
          score: m['score'] as String? ?? '',
          minute: m['minute'] as String? ?? '',
          status: status,
        );
      }).toList();

      final rawStatus = row['status'] as String? ?? 'pending';
      final mappedStatus = rawStatus == 'lost' ? 'risk'
          : rawStatus == 'won' ? 'winning'
          : rawStatus == 'active' ? 'pending'
          : rawStatus;
      final status = CouponStatus.values.firstWhere(
        (s) => s.name == mappedStatus,
        orElse: () => CouponStatus.pending,
      );

      coupons.add(
        Coupon(
          id: int.tryParse(row['id'].toString()),
          title: row['title'] as String? ?? '',
          meta: row['meta'] as String? ?? '',
          status: status,
          stake: row['stake'] as String? ?? '',
          potential: row['potential'] as String? ?? '',
          progress: matches.map((m) => m.status).toList(),
          matches: matches,
        ),
      );
    }

    return coupons;
  }
}