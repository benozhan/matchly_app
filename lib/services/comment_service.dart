import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_config.dart';

class CouponComment {
  final String id;
  final String couponId;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final String? parentCommentId;

  CouponComment({
    required this.id,
    required this.couponId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
  });

  factory CouponComment.fromJson(Map<String, dynamic> j) => CouponComment(
    id: j['id'] as String,
    couponId: j['coupon_id'] as String,
    userId: j['user_id'] as String,
    username: j['username'] as String,
    content: j['content'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    parentCommentId: j['parent_comment_id'] as String?,
  );
}

class CommentService {
  CommentService._();
  static final instance = CommentService._();
  final _client = Supabase.instance.client;
  final _http = http.Client();

  Future<List<CouponComment>> getComments(String couponId) async {
    final res = await _client
        .from('coupon_comments')
        .select()
        .eq('coupon_id', couponId)
        .order('created_at', ascending: true);
    return (res as List).map((j) => CouponComment.fromJson(j)).toList();
  }

  Future<void> addComment(String couponId, String username, String content, {String? parentCommentId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final inserted = await _client.from('coupon_comments').insert({
      'coupon_id': couponId,
      'user_id': userId,
      'username': username,
      'content': content,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
    }).select().single();
    final commentId = inserted['id'] as String?;
    if (commentId != null) _notifyComment(couponId, commentId);
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('coupon_comments').delete().eq('id', commentId);
  }

  /// Bir yorumu şikayet eder. Aynı yorumu ikinci kez şikayet etmeye
  /// çalışırsa (unique constraint) `false` döner, aksi halde `true`.
  Future<bool> reportComment(String commentId, String reason) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      await _client.from('comment_reports').insert({
        'comment_id': commentId,
        'reporter_id': userId,
        'reason': reason,
      });
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return false;
      rethrow;
    }
  }

  Future<void> _notifyComment(String couponId, String commentId) async {
    try {
      await _http.post(
        Uri.parse('$kApiBaseUrl/social/notify-comment'),
        headers: apiHeaders(json: true),
        body: jsonEncode({'couponId': couponId, 'commentId': commentId}),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
