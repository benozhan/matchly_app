import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/shared_coupon_detail_page.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'services/social_service.dart';

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
  StreamSubscription<AuthState>? _authSubscription;
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _signedIn = Supabase.instance.client.auth.currentSession != null;
    if (_signedIn) NotificationService.instance.initialize();
    _loadTheme();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final signedIn = data.session != null;
      if (_signedIn != signedIn) setState(() => _signedIn = signedIn);
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? true;
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.dark;
    await prefs.setBool('isDarkTheme', !isDark);
    setState(() => _themeMode = isDark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleSignedIn() {
    setState(() => _signedIn = true);
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
      themeMode: _themeMode,
      home: _signedIn
          ? const MatchlyHomePage()
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
