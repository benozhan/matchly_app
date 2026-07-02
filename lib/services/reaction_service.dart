import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_config.dart';

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
  final _http = http.Client();

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
      if (type == 'like') _notifyReaction(couponId);
    } else if (existing['type'] == type) {
      // Aynı reaksiyona tekrar basılırsa kaldır
      await _client.from('coupon_reactions').delete().eq('id', existing['id']);
    } else {
      // Farklı reaksiyona geçiş (like -> dislike veya tam tersi)
      await _client.from('coupon_reactions').update({'type': type}).eq('id', existing['id']);
      if (type == 'like') _notifyReaction(couponId);
    }
  }

  Future<void> _notifyReaction(String couponId) async {
    try {
      await _http.post(
        Uri.parse('$kApiBaseUrl/social/notify-reaction'),
        headers: apiHeaders(json: true),
        body: jsonEncode({'couponId': couponId}),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
