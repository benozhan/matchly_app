import 'package:supabase_flutter/supabase_flutter.dart';

class CouponComment {
  final String id;
  final String couponId;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;

  CouponComment({
    required this.id,
    required this.couponId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory CouponComment.fromJson(Map<String, dynamic> j) => CouponComment(
    id: j['id'] as String,
    couponId: j['coupon_id'] as String,
    userId: j['user_id'] as String,
    username: j['username'] as String,
    content: j['content'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class CommentService {
  CommentService._();
  static final instance = CommentService._();
  final _client = Supabase.instance.client;

  Future<List<CouponComment>> getComments(String couponId) async {
    final res = await _client
        .from('coupon_comments')
        .select()
        .eq('coupon_id', couponId)
        .order('created_at', ascending: true);
    return (res as List).map((j) => CouponComment.fromJson(j)).toList();
  }

  Future<void> addComment(String couponId, String username, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('coupon_comments').insert({
      'coupon_id': couponId,
      'user_id': userId,
      'username': username,
      'content': content,
    });
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('coupon_comments').delete().eq('id', commentId);
  }
}
