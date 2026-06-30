import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:convert';
import '../../services/social_service.dart';

import '../../core/app_colors.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _usernameController = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('Apple ID token alınamadı');
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      widget.onSignedIn();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'matchly://login-callback',
      );
      widget.onSignedIn();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isLogin && username.isEmpty) {
      setState(() => _error = 'Kullanıcı adı gerekli');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'E-posta ve şifre gerekli');
      return;
    }
    if (!_isLogin) {
      if (password.length < 8) {
        setState(() => _error = 'Şifre en az 8 karakter olmalı');
        return;
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        setState(() => _error = 'Şifre en az bir rakam içermeli');
        return;
      }
      if (password != _passwordConfirmController.text.trim()) {
        setState(() => _error = 'Şifreler eşleşmiyor');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'username': username,
            'displayName': username,
          },
        );
        // Backend'e kullanıcı kaydı
        try {
          await SocialService.instance.ensureUser(username, username);
        } catch (_) {}
      }

      widget.onSignedIn();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Bir hata oluştu');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Giriş yap' : 'Hesap oluştur';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 24),
              children: [
                Text(
                  'Matchly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kuponlarını hesabına kaydet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),

                if (!_isLogin) ...[
                  _AuthField(
                    controller: _usernameController,
                    hint: 'Kullanıcı adı',
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 12),
                ],

                AutofillGroup(
                  child: Column(
                    children: [
                      _AuthField(
                        controller: _emailController,
                        hint: 'E-posta',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 12),
                      _AuthField(
                        controller: _passwordController,
                        hint: 'Şifre',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 12),
                        _AuthField(
                          controller: _passwordConfirmController,
                          hint: 'Şifre tekrar',
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                        ),
                      ],
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0E8DA),
                      foregroundColor: const Color(0xFF101010),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Ayırıcı ──────────────────────────────────────────────
                Row(children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('veya', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ]),
                const SizedBox(height: 16),

                // ── Apple ile Giriş ───────────────────────────────────────
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithApple,
                    icon: const Icon(Icons.apple, size: 20),
                    label: const Text('Apple ile Devam Et', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Google ile Giriş ──────────────────────────────────────
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _signInWithGoogle,
                    icon: const Text('G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
                    label: const Text('Google ile Devam Et', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _isLogin = !_isLogin;
                            _error   = null;
                          }),
                  child: Text(
                    _isLogin
                        ? 'Hesabın yok mu? Kayıt ol'
                        : 'Zaten hesabın var mı? Giriş yap',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 18),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textTertiary.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}