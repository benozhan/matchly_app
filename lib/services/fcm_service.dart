import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  Future<void> registerToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: Bildirim izni reddedildi');
        return;
      }

      String? token;

      if (kIsWeb) {
        // Firebase Console → Project Settings → Cloud Messaging → Web Push certificates
        const vapidKey = 'BMp8YoKQRlvT29myjX9kBWkwOD1InqWwFNPMXSMMjgEM_wqRmuentameirrQEdijzdLsnfb7ll3vrpfKUXfNIlk';
        token = await messaging.getToken(vapidKey: vapidKey);
      } else {
        token = await messaging.getToken();
      }

      if (token == null) {
        debugPrint('FCM TOKEN: null — token alınamadı');
        return;
      }

      debugPrint('FCM TOKEN: $token');

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('FCM: Supabase kullanıcısı bulunamadı, token kaydedilmedi');
        return;
      }

      final platform = _resolvePlatform();

      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );

      debugPrint('FCM: Token kaydedildi — platform: $platform');
    } catch (e, st) {
      debugPrint('FCM: Token kaydedilemedi — $e');
      debugPrint('$st');
    }
  }

  String _resolvePlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.windows:
        return 'windows';
      default:
        return 'other';
    }
  }
}
