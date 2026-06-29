import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const String _kBaseUrl = 'http://167.172.182.128:8001';
const Duration _kTimeout = Duration(seconds: 10);

// ── Models ────────────────────────────────────────────────────────────────────

class SocialUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatar;
  final String createdAt;
  final int followerCount;
  final int followingCount;

  const SocialUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.createdAt,
    required this.followerCount,
    required this.followingCount,
  });

  factory SocialUser.fromJson(Map<String, dynamic> j) => SocialUser(
        id:             j['id']             as String? ?? '',
        username:       j['username']       as String? ?? '',
        displayName:    j['displayName']    as String? ?? '',
        avatar:         j['avatar']         as String?,
        createdAt:      j['createdAt']      as String? ?? '',
        followerCount:  j['followerCount']  as int?    ?? 0,
        followingCount: j['followingCount'] as int?    ?? 0,
      );
}

class SharedCoupon {
  final String id;
  final String couponId;
  final bool isPublic;
  final String createdAt;
  final String note;

  const SharedCoupon({
    required this.id,
    required this.couponId,
    required this.isPublic,
    required this.createdAt,
    this.note = '',
  });

  factory SharedCoupon.fromJson(Map<String, dynamic> j) => SharedCoupon(
        id:        j['id']        as String? ?? '',
        couponId:  j['couponId']  as String? ?? '',
        isPublic:  j['isPublic']  as bool?   ?? true,
        createdAt: j['createdAt'] as String? ?? '',
        note:      j['note']      as String? ?? '',
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  final _client = http.Client();

  Future<SocialUser> getUser(String username) async {
    final res = await _client
        .get(Uri.parse('$_kBaseUrl/social/users/$username'))
        .timeout(_kTimeout);
    _checkStatus(res);
    return SocialUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<SocialUser>> getFollowers(String username) async {
    final res = await _client
        .get(Uri.parse('$_kBaseUrl/social/users/$username/followers'))
        .timeout(_kTimeout);
    _checkStatus(res);
    return (jsonDecode(res.body) as List)
        .cast<Map<String, dynamic>>()
        .map(SocialUser.fromJson)
        .toList();
  }

  Future<List<SocialUser>> getFollowing(String username) async {
    final res = await _client
        .get(Uri.parse('$_kBaseUrl/social/users/$username/following'))
        .timeout(_kTimeout);
    _checkStatus(res);
    return (jsonDecode(res.body) as List)
        .cast<Map<String, dynamic>>()
        .map(SocialUser.fromJson)
        .toList();
  }

  Future<List<SharedCoupon>> getSharedCoupons(String username) async {
    final res = await _client
        .get(Uri.parse('$_kBaseUrl/social/users/$username/shared-coupons'))
        .timeout(_kTimeout);
    _checkStatus(res);
    return (jsonDecode(res.body) as List)
        .cast<Map<String, dynamic>>()
        .map(SharedCoupon.fromJson)
        .toList();
  }

  /// Creates or updates a shared coupon record on the social backend.
  /// Fire-and-forget safe — swallows errors so the share flow is never blocked.
  Future<SharedCoupon?> createOrUpdateSharedCoupon({
    required String couponId,
    required String ownerUsername,
    bool isPublic = true,
    String note = '',
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_kBaseUrl/social/shared-coupons'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'couponId': couponId,
              'ownerUsername': ownerUsername,
              'isPublic': isPublic,
              'note': note,
            }),
          )
          .timeout(_kTimeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return SharedCoupon.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {
      // Non-blocking — share text was already copied to clipboard.
    }
    return null;
  }

  /// Saves full coupon detail to the backend. Fire-and-forget.
  Future<void> saveCouponDetail({
    required String couponId,
    required String ownerUsername,
    required String title,
    required String siteName,
    required String stake,
    required String odds,
    required String potential,
    required String status,
    required List<Map<String, String>> selections,
  }) async {
    try {
      await _client
          .post(
            Uri.parse('$_kBaseUrl/social/coupons'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'couponId':      couponId,
              'ownerUsername': ownerUsername,
              'title':         title,
              'siteName':      siteName,
              'stake':         stake,
              'odds':          odds,
              'potential':     potential,
              'status':        status,
              'selections':    selections,
            }),
          )
          .timeout(_kTimeout);
    } catch (_) {
      // Non-blocking.
    }
  }

  /// Fetches full coupon detail from backend. Returns null on error/not-found.
  Future<CouponDetail?> getCouponDetail(String couponId) async {
    // Önce backend'den dene
    try {
      final res = await _client
          .get(Uri.parse('$_kBaseUrl/social/coupons/$couponId'))
          .timeout(_kTimeout);
      if (res.statusCode == 200) {
        return CouponDetail.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}

    // Backend bulamazsa Supabase'den direkt çek
    try {
      final sb = Supabase.instance.client;
      final coupon = await sb
          .from('coupons')
          .select('*, coupon_matches(*)')
          .eq('id', couponId)
          .single();
      final matches = (coupon['coupon_matches'] as List? ?? []);
      final oddsMatch = RegExp(r'×([\d.,]+)').firstMatch(coupon['meta'] as String? ?? '');
      return CouponDetail(
        couponId: couponId,
        ownerUsername: coupon['owner_username'] as String? ?? '',
        ownerDisplayName: coupon['owner_username'] as String? ?? '',
        title: coupon['title'] as String? ?? '',
        siteName: (coupon['meta'] as String? ?? '').split('·').first.trim(),
        stake: coupon['stake'] as String? ?? '',
        odds: oddsMatch != null ? '×${oddsMatch.group(1)}' : '',
        potential: coupon['potential'] as String? ?? '',
        status: coupon['status'] as String? ?? 'pending',
        createdAt: coupon['created_at'] as String? ?? '',
        selections: matches.map<CouponSelection>((m) => CouponSelection(
          matchName: m['teams'] as String? ?? '',
          betType: m['selection'] as String? ?? '',
          status: m['status'] as String? ?? 'pending',
          lastScore: m['score'] as String? ?? '',
        )).toList(),
      );
    } catch (_) {}
    return null;
  }

  /// Searches users by username or displayName.
  Future<void> ensureUser(String username, String displayName) async {
    try {
      await _client.post(
        Uri.parse('$_kBaseUrl/social/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'displayName': displayName, 'avatar': ''}),
      ).timeout(_kTimeout);
    } catch (_) {}
  }

  Future<SocialUser?> updateAvatar(String username, String avatarUrl) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$_kBaseUrl/social/users/$username/update'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'displayName': '', 'avatar': avatarUrl}),
          )
          .timeout(_kTimeout);
      if (res.statusCode == 200) {
        return SocialUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<List<SocialUser>> searchUsers(String q) async {
    if (q.trim().isEmpty) return [];
    final res = await _client
        .get(Uri.parse(
            '$_kBaseUrl/social/find-users?q=${Uri.encodeQueryComponent(q.trim())}'))
        .timeout(_kTimeout);
    _checkStatus(res);
    return (jsonDecode(res.body) as List)
        .cast<Map<String, dynamic>>()
        .map(SocialUser.fromJson)
        .toList();
  }

  /// Returns activity feed for [username] (coupons from followed users).
  Future<List<FeedItem>> getFeed(String username) async {
    final res = await _client
        .get(Uri.parse('$_kBaseUrl/social/feed/$username'))
        .timeout(_kTimeout);
    _checkStatus(res);
    return (jsonDecode(res.body) as List)
        .cast<Map<String, dynamic>>()
        .map(FeedItem.fromJson)
        .toList();
  }

  /// Follows [followingId] as [followerId]. Fire-and-forget safe.
  Future<void> follow(String followerId, String followingId) async {
    try {
      await _client
          .post(
            Uri.parse('$_kBaseUrl/social/follow'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'followerId': followerId, 'followingId': followingId}),
          )
          .timeout(_kTimeout);
    } catch (_) {}
  }

  /// Unfollows [followingId] as [followerId]. Fire-and-forget safe.
  Future<void> unfollow(String followerId, String followingId) async {
    try {
      await _client
          .delete(
            Uri.parse('$_kBaseUrl/social/follow'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'followerId': followerId, 'followingId': followingId}),
          )
          .timeout(_kTimeout);
    } catch (_) {}
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode != 200) {
      throw SocialException('Server error ${res.statusCode}', res.statusCode);
    }
  }

  void dispose() => _client.close();
}

// ── CouponDetail models ───────────────────────────────────────────────────────

class CouponSelection {
  final String matchName;
  final String betType;
  final String status;
  final String lastScore;

  const CouponSelection({
    required this.matchName,
    required this.betType,
    required this.status,
    required this.lastScore,
  });

  factory CouponSelection.fromJson(Map<String, dynamic> j) => CouponSelection(
        matchName: j['matchName'] as String? ?? '',
        betType:   j['betType']  as String? ?? '',
        status:    j['status']   as String? ?? 'pending',
        lastScore: j['lastScore'] as String? ?? '',
      );
}

class CouponDetail {
  final String couponId;
  final String ownerUsername;
  final String ownerDisplayName;
  final String title;
  final String siteName;
  final String stake;
  final String odds;
  final String potential;
  final String status;
  final String createdAt;
  final List<CouponSelection> selections;

  const CouponDetail({
    required this.couponId,
    required this.ownerUsername,
    required this.ownerDisplayName,
    required this.title,
    required this.siteName,
    required this.stake,
    required this.odds,
    required this.potential,
    required this.status,
    required this.createdAt,
    required this.selections,
  });

  factory CouponDetail.fromJson(Map<String, dynamic> j) => CouponDetail(
        couponId:         j['couponId']         as String? ?? '',
        ownerUsername:    j['ownerUsername']     as String? ?? '',
        ownerDisplayName: j['ownerDisplayName']  as String? ?? '',
        title:            j['title']             as String? ?? '',
        siteName:         j['siteName']          as String? ?? '',
        stake:            j['stake']             as String? ?? '',
        odds:             j['odds']              as String? ?? '',
        potential:        j['potential']         as String? ?? '',
        status:           j['status']            as String? ?? 'pending',
        createdAt:        j['createdAt']         as String? ?? '',
        selections: (j['selections'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(CouponSelection.fromJson)
            .toList(),
      );
}

// ── Exception ─────────────────────────────────────────────────────────────────

class SocialException implements Exception {
  final String message;
  final int? statusCode;
  const SocialException(this.message, [this.statusCode]);

  @override
  String toString() => 'SocialException: $message';
}

// ── FeedItem model ────────────────────────────────────────────────────────────

class FeedItem {
  final String type;         // SHARED_COUPON | COUPON_WON | COUPON_LOST
  final String username;
  final String displayName;
  final String couponId;
  final String createdAt;

  const FeedItem({
    required this.type,
    required this.username,
    required this.displayName,
    required this.couponId,
    required this.createdAt,
  });

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
        type:        j['type']        as String? ?? 'SHARED_COUPON',
        username:    j['username']    as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        couponId:    j['couponId']    as String? ?? '',
        createdAt:   j['createdAt']   as String? ?? '',
      );
}
