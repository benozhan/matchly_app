import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/app_theme.dart';
import 'core/app_state.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/shared_coupon_detail_page.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'services/social_service.dart';

String? _pendingCouponId;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    OneSignal.initialize('74407b16-edac-4633-8b50-a9684cf8e838');
    OneSignal.Notifications.requestPermission(true);
  } catch (e) {
    debugPrint('OneSignal error: $e');
  }

  try {
    await Supabase.initialize(
      url: 'https://npesbmrndcxyhygsqrro.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wZXNibXJuZGN4eWh5Z3NxcnJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyNDk5ODgsImV4cCI6MjA5NzgyNTk4OH0.8ig30ARWHSW1PSZ7JpK3B38wW1pJhUSep5nICs6PHEc',
    );
  } catch (e) {
    debugPrint('Supabase error: $e');
  }

  runApp(const MatchlyApp());
}

class MatchlyApp extends StatefulWidget {
  const MatchlyApp({super.key});

  static _MatchlyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MatchlyAppState>();

  @override
  State<MatchlyApp> createState() => _MatchlyAppState();
}

class _MatchlyAppState extends State<MatchlyApp> {
  late bool _signedIn;
  bool _needsUsername = false;
  final _appLinks = AppLinks();
  String? _pendingDeepLink;
  StreamSubscription<AuthState>? _authSubscription;


  @override
  void initState() {
    super.initState();
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'matchly' && uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'coupon') {
        final couponId = uri.pathSegments[1];
        setState(() => _pendingDeepLink = couponId);
      }
    });
    _signedIn = Supabase.instance.client.auth.currentSession != null;
    if (_signedIn) NotificationService.instance.initialize();
    AppState.instance.init();
    AppState.instance.addListener(() => setState(() {}));
    // Bildirim tap handler
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null && data['coupon_id'] != null) {
        setState(() {
          _pendingCouponId = data['coupon_id'].toString();
        });
      }
    });
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final signedIn = data.session != null;
      if (_signedIn != signedIn) setState(() => _signedIn = signedIn);
    });
  }



  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleSignedIn() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Google/Apple ile girişte username yoksa username ekranı göster
      final meta = user.userMetadata ?? {};
      final email = user.email ?? '';
      final hasUsername = meta['username'] != null;
      if (!hasUsername && (user.appMetadata['provider'] == 'google' || user.appMetadata['provider'] == 'apple')) {
        setState(() => _needsUsername = true);
        return;
      }
    }
    setState(() => _signedIn = true);
    FcmService.instance.registerToken();
    NotificationService.instance.initialize();
  }

  Future<void> _handleUsernameSet(String username) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final displayName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? username;
    await SocialService.instance.ensureUser(username, displayName);
    setState(() { _needsUsername = false; _signedIn = true; });
    FcmService.instance.registerToken();
    NotificationService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matchly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: AppState.instance.locale,
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: AppState.instance.themeMode,
      home: _signedIn
          ? MatchlyHomePage(pendingCouponId: _pendingCouponId)
          : _needsUsername
              ? _UsernameSetupPage(onDone: _handleUsernameSet)
              : AuthPage(onSignedIn: _handleSignedIn),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    if (uri != null &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments[0] == 'coupon') {
      final couponId = uri.pathSegments[1];
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => SharedCouponDetailPage(
          sharedCoupon: SharedCoupon(
            id: couponId,
            couponId: couponId,
            isPublic: true,
            createdAt: '',
          ),
          localCoupon: null,
          owner: null,
        ),
      );
    }
    return MaterialPageRoute(builder: (_) => const MatchlyHomePage());
  }
}


class _UsernameSetupPage extends StatefulWidget {
  final Future<void> Function(String username) onDone;
  const _UsernameSetupPage({required this.onDone});

  @override
  State<_UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<_UsernameSetupPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _controller.text.trim().toLowerCase().replaceAll(' ', '_');
    if (username.isEmpty) {
      setState(() => _error = 'Kullanıcı adı gerekli');
      return;
    }
    if (username.length < 3) {
      setState(() => _error = 'En az 3 karakter olmalı');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await widget.onDone(username);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('Kullanıcı adı seç', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F1C2E))),
              const SizedBox(height: 8),
              const Text('Bu ad profilinde görünecek.', style: TextStyle(fontSize: 14, color: Color(0xFF7A8FA8))),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'kullanici_adi',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D4A6E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Devam Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}