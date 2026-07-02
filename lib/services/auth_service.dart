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

  factory AppUser.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? balanceJson}) {
    return AppUser(
      id:          json['id']           as String? ?? '',
      username:    json['username']     as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      startingBalance: (balanceJson?['starting_balance'] as num?)?.toDouble(),
      netProfitBaseline: (balanceJson?['net_profit_baseline'] as num?)?.toDouble(),
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

    // Kasa verisi (starting_balance/net_profit_baseline) ayrı, sadece
    // sahibinin okuyabildiği "user_balances" tablosunda tutuluyor —
    // profiles tablosunun SELECT politikası herkese açık olduğu için
    // para bilgisi orada saklanmaz (bkz. user_balances RLS: user_id = auth.uid()).
    final balance = await _client
        .from('user_balances')
        .select()
        .eq('user_id', authUser.id)
        .maybeSingle();

    return AppUser.fromJson(data, balanceJson: balance);
  }

  /// Kasayi (baslangic bakiyesi) gunceller. `netProfitBaseline`, bu anki
  /// tum-zamanlarin net kar/zararidir - kasa formulu buna gore, girilen
  /// tutarin O AN tam olarak goruntulenmesini saglar (bkz. home_page.dart
  /// _kasa getter'i).
  Future<void> updateStartingBalance(double value, double netProfitBaseline) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return;
    await _client.from('user_balances').upsert({
      'user_id': authUser.id,
      'starting_balance': value,
      'net_profit_baseline': netProfitBaseline,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
