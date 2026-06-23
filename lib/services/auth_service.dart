import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String username;
  final String displayName;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:          json['id']           as String? ?? '',
      username:    json['username']     as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  bool get isSignedIn => _client.auth.currentSession != null;

  Future<AppUser?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (data == null) return null;
    return AppUser.fromJson(data);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}