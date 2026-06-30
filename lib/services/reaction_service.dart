import 'package:supabase_flutter/supabase_flutter.dart';

class ReactionCounts {
  final int likes;
  final int dislikes;
  final String? userReaction; // 'like', 'dislike', or null

  ReactionCounts({required this.likes, required this.dislikes, this.userReaction});
}

class ReactionService {
  ReactionService._();
  static final instance = ReactionService._();
  final _client = Supabase.instance.client;

  Future<ReactionCounts> getReactions(String couponId) async {
    final res = await _client
        .from('coupon_reactions')
        .select('type, user_id')
        .eq('coupon_id', couponId);

    final rows = res as List;
    final currentUserId = _client.auth.currentUser?.id;
    int likes = 0, dislikes = 0;
    String? userReaction;

    for (final row in rows) {
      final type = row['type'] as String;
      if (type == 'like') likes++;
      if (type == 'dislike') dislikes++;
      if (row['user_id'] == currentUserId) userReaction = type;
    }

    return ReactionCounts(likes: likes, dislikes: dislikes, userReaction: userReaction);
  }

  Future<void> setReaction(String couponId, String type) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final existing = await _client
        .from('coupon_reactions')
        .select('id, type')
        .eq('coupon_id', couponId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('coupon_reactions').insert({
        'coupon_id': couponId,
        'user_id': userId,
        'type': type,
      });
    } else if (existing['type'] == type) {
      // Aynı reaksiyona tekrar basılırsa kaldır
      await _client.from('coupon_reactions').delete().eq('id', existing['id']);
    } else {
      // Farklı reaksiyona geçiş (like -> dislike veya tam tersi)
      await _client.from('coupon_reactions').update({'type': type}).eq('id', existing['id']);
    }
  }
}
