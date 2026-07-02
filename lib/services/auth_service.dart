import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String username;
  final String displayName;
  final double? startingBalance;
  final double? netProfitBaseline;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.startingBalance,
    this.netProfitBaseline,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:          json['id']           as String? ?? '',
      username:    json['username']     as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      startingBalance: (json['starting_balance'] as num?)?.toDouble(),
      netProfitBaseline: (json['net_profit_baseline'] as num?)?.toDouble(),
    );
  }

  AppUser copyWith({double? startingBalance, double? netProfitBaseline}) => AppUser(
    id: id,
    username: username,
    displayName: displayName,
    startingBalance: startingBalance ?? this.startingBalance,
    netProfitBaseline: netProfitBaseline ?? this.netProfitBaseline,
  );
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

  /// Kasayi (baslangic bakiyesi) gunceller. `netProfitBaseline`, bu anki
  /// tum-zamanlarin net kar/zararidir - kasa formulu buna gore, girilen
  /// tutarin O AN tam olarak goruntulenmesini saglar (bkz. home_page.dart
  /// _kasa getter'i).
  Future<void> updateStartingBalance(double value, double netProfitBaseline) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return;
    await _client
        .from('profiles')
        .update({
          'starting_balance': value,
          'net_profit_baseline': netProfitBaseline,
        })
        .eq('id', authUser.id);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
