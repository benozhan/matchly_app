import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/shared_coupon_detail_page.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/social_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://npesbmrndcxyhygsqrro.supabase.co',
    anonKey: 'sb_publishable_WWEq0ERvj1vNjj321jRROQ_t9I4SCEP',
  );

  runApp(const MatchlyApp());
}

class MatchlyApp extends StatefulWidget {
  const MatchlyApp({super.key});

  @override
  State<MatchlyApp> createState() => _MatchlyAppState();
}

class _MatchlyAppState extends State<MatchlyApp> {
  late bool _signedIn;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _signedIn = Supabase.instance.client.auth.currentSession != null;

    // Uygulama açıldığında zaten giriş yapılmışsa token al
    if (_signedIn) {
      FcmService.instance.registerToken();
    }

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final wasSignedIn = _signedIn;
      setState(() {
        _signedIn = data.session != null;
      });
      // Yeni oturum açıldığında token al
      if (!wasSignedIn && _signedIn) {
        FcmService.instance.registerToken();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _handleSignedIn() {
    setState(() => _signedIn = true);
    FcmService.instance.registerToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matchly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: _signedIn
          ? const MatchlyHomePage()
          : AuthPage(onSignedIn: _handleSignedIn),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  /// Named route handler — enables Flutter Web URL persistence.
  /// /coupon/:id → SharedCouponDetailPage (fetches own data from backend)
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
            id:        couponId,
            couponId:  couponId,
            isPublic:  true,
            createdAt: '',
          ),
          localCoupon: null,
          owner:       null,
        ),
      );
    }
    return MaterialPageRoute(builder: (_) => const MatchlyHomePage());
  }
}
