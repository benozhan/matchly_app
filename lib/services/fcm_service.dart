import 'package:flutter/foundation.dart';

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  Future<void> registerToken() async {
    debugPrint('FCM: iOS 27 beta - Firebase devre dışı');
  }
}
