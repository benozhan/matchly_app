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
        // Web: VAPID key ile token al
        const vapidKey =
            'BMp8YoKQRlvT29myjX9kBWkwOD1InqWwFNPMXSMMjgEM_wqRmuentameirrQEdijzdLsnfb7ll3vrpfKUXfNIlk';
        token = await messaging.getToken(vapidKey: vapidKey);
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        // iOS / macOS: APNs token olmadan getToken() çağrılamaz.
        // Önce APNs token beklenir, gelmezse FCM token istenmez.
        final apnsToken = await _waitForApnsToken(messaging);
        if (apnsToken == null) {
          debugPrint('FCM: 10 denemede APNs token alınamadı, FCM token atlandı');
          return;
        }
        debugPrint('FCM: APNs token hazır, FCM token isteniyor');
        token = await messaging.getToken();
      } else {
        // Android ve diğer platformlar
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

  /// iOS / macOS için APNs token gelene kadar 1 saniye arayla 10 kez dener.
  /// getAPNSToken() exception atarsa yakalar, bir sonraki denemeye geçer.
  /// 10 denemede de null / exception ise null döner → getToken() çağrılmaz.
  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 1; attempt <= 10; attempt++) {
      try {
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
          debugPrint('FCM: APNs token alındı (deneme $attempt/10)');
          return apnsToken;
        }
      } catch (e) {
        debugPrint('FCM: getAPNSToken() deneme $attempt/10 hata — $e');
      }
      debugPrint('FCM: APNs token bekleniyor (deneme $attempt/10)...');
      await Future.delayed(const Duration(seconds: 1));
    }
    return null;
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
