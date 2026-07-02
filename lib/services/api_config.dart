import 'package:supabase_flutter/supabase_flutter.dart';

/// KuponBot VPS backend'inin taban adresi.
/// HTTPS (matchlyapp.com + Let's Encrypt) üzerinden — tüm trafik şifreli.
const String kApiBaseUrl = 'https://matchlyapp.com';

/// Backend isteklerinde kullanılacak header'ları üretir.
/// Kullanıcı giriş yapmışsa Supabase access token'ını `Authorization: Bearer`
/// olarak ekler — böylece backend kimliği token'dan doğrular (taklit imkânsız).
Map<String, String> apiHeaders({bool json = false}) {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  return {
    if (json) 'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
