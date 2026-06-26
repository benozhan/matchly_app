import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isRead: json['read_at'] != null,
    );
  }
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _client = Supabase.instance.client;
  final List<AppNotification> _notifications = [];
  final ValueNotifier<int> unreadCount = ValueNotifier(0);
  final ValueNotifier<AppNotification?> latest = ValueNotifier(null);

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> initialize() async {
    await _loadNotifications();
    _subscribeToRealtime();
  }

  Future<void> _loadNotifications() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      final res = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      _notifications.clear();
      _notifications.addAll(
        (res as List).map((e) => AppNotification.fromJson(e)),
      );
      _updateUnreadCount();
    } catch (e) {
      debugPrint('NotificationService load error: $e');
    }
  }

  void _subscribeToRealtime() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final data = payload.newRecord;
            if (data['user_id'] != userId) return;
            final notification = AppNotification.fromJson(data);
            _notifications.insert(0, notification);
            latest.value = notification;
            _updateUnreadCount();
          },
        )
        .subscribe();
  }

  void _updateUnreadCount() {
    unreadCount.value = _notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAllRead() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('notifications')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .isFilter('read_at', null);

      for (final n in _notifications) {
        n.isRead = true;
      }
      _updateUnreadCount();
    } catch (e) {
      debugPrint('markAllRead error: $e');
    }
  }
}
