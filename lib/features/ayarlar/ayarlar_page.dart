import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../models/coupon.dart';
import '../../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_page.dart';
import '../coupon/coupon_detail_page.dart';
import '../gecmis/gecmis_page.dart';
import '../profile/my_profile_page.dart';

class AyarlarPage extends StatefulWidget {
  final List<Coupon> coupons;
  const AyarlarPage({super.key, this.coupons = const []});

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> {
  AppUser? _user;
  bool _bildirimler         = true;
  bool _karanlikTema        = AppState.instance.themeMode == ThemeMode.dark;
  bool _otomatikGuncelleme  = false;
  TimeOfDay _gunSonuSaati = const TimeOfDay(hour: 0, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.getCurrentUser();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    TimeOfDay? savedTime;
    if (uid != null) {
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('daily_report_hour,daily_report_minute')
            .eq('id', uid)
            .single();
        if (profile != null) {
          final h = profile['daily_report_hour'] as int? ?? 0;
          final m = profile['daily_report_minute'] as int? ?? 0;
          savedTime = TimeOfDay(hour: h, minute: m);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      if (savedTime != null) _gunSonuSaati = savedTime;
    });
  }

  Future<void> _changeUsername(BuildContext context) async {
    final ctrl = TextEditingController(text: _user?.username ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kullanıcı Adı Değiştir', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Yeni kullanıcı adı',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Kaydet', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        await Supabase.instance.client.from('profiles').update({'username': result}).eq('id', uid);
        await _loadUser();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Şifre Değiştir", style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PwField(ctrl: oldCtrl, hint: "Mevcut şifre"),
              const SizedBox(height: 10),
              _PwField(ctrl: newCtrl, hint: "Yeni şifre (min 8 karakter, rakam içermeli)"),
              const SizedBox(height: 10),
              _PwField(ctrl: confirmCtrl, hint: "Yeni şifre tekrar"),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(dialogError!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: AppColors.textSecondary))),
            TextButton(
              onPressed: () async {
                final oldP = oldCtrl.text.trim();
                final newP = newCtrl.text.trim();
                final conf = confirmCtrl.text.trim();
                if (oldP.isEmpty) { setS(() => dialogError = "Mevcut şifre gerekli"); return; }
                if (newP.length < 8) { setS(() => dialogError = "En az 8 karakter olmalı"); return; }
                if (!newP.contains(RegExp(r"[0-9]"))) { setS(() => dialogError = "En az bir rakam içermeli"); return; }
                if (newP != conf) { setS(() => dialogError = "Şifreler eşleşmiyor"); return; }
                try {
                  final email = Supabase.instance.client.auth.currentUser?.email ?? "";
                  await Supabase.instance.client.auth.signInWithPassword(email: email, password: oldP);
                  await Supabase.instance.client.auth.updateUser(UserAttributes(password: newP));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre güncellendi ✓")));
                } catch (e) {
                  setS(() => dialogError = "Mevcut şifre yanlış");
                }
              },
              child: const Text("Kaydet", style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text('Hesabından çıkmak istediğine emin misin?', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkış Yap', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed != true) return;
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthPage(
          onSignedIn: () {},
        ),
      ),
      (_) => false,
    );
  }

  static BoxDecoration _sectionDeco() => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      );

  void _showComingSoon(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: const Text(
          'Bu özellik yakında geliyor',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [

        // ── Profile banner ───────────────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyProfilePage(
                user: _user,
                coupons: widget.coupons,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.border,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar initials circle
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.brand, AppColors.brand.withOpacity(0.60)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (_user?.displayName.isNotEmpty == true
                            ? _user!.displayName.trim().substring(0, _user!.displayName.trim().length.clamp(0, 2))
                            : 'U')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user?.displayName ?? 'Kullanıcı',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${_user?.username ?? 'user'}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Header ───────────────────────────────────────────────────────────
        const Text(
          'Ayarlar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Uygulama tercihleri',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // ── Hesap ────────────────────────────────────────────────────────────
        _SectionLabel('HESAP'),
        const SizedBox(height: 8),
        Container(
          decoration: _sectionDeco(),
          child: Column(
            children: [
              _ValueRow(
                icon: Icons.person_outline_rounded,
                title: 'Kullanıcı Adı Değiştir',
                value: '@${_user?.username ?? ''}',
                onTap: () => _changeUsername(context),
              ),
              _RowDivider(),
              _ValueRow(
                icon: Icons.lock_outline_rounded,
                title: 'Şifre Değiştir',
                value: '••••••••',
                onTap: () => _changePassword(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Geçmiş ───────────────────────────────────────────────────────────
        _SectionLabel('GEÇMİŞ'),
        const SizedBox(height: 8),
        Container(
          decoration: _sectionDeco(),
          child: _ActionRow(
            icon: Icons.history_rounded,
            title: 'Kupon Geçmişi',
            subtitle: 'Tamamlanan kuponları görüntüle',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    title: const Text('Kupon Geçmişi', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  body: Theme(
                    data: Theme.of(ctx).copyWith(
                      textTheme: Theme.of(ctx).textTheme.apply(decoration: TextDecoration.none),
                    ),
                    child: GecmisPage(
                  coupons: widget.coupons,
                  onCouponTap: (c) => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => CouponDetailPage(
                        coupon: c,
                        resolved: true,
                        allCoupons: widget.coupons,
                      ),
                    ),
                  ),
                ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Genel ────────────────────────────────────────────────────────────
        _SectionLabel('GENEL'),
        const SizedBox(height: 8),
        Container(
          decoration: _sectionDeco(),
          child: Column(
            children: [
              _ToggleRow(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                subtitle: 'Kupon güncellemeleri',
                value: _bildirimler,
                onChanged: (v) => setState(() => _bildirimler = v),
              ),
              _RowDivider(),
              _ToggleRow(
                icon: Icons.dark_mode_outlined,
                title: 'Karanlık Tema',
                subtitle: 'Uygulama görünümü',
                value: _karanlikTema,
                onChanged: (v) { setState(() => _karanlikTema = v); AppState.instance.toggleTheme(); },
              ),
              _RowDivider(),
              _ToggleRow(
                icon: Icons.sync_outlined,
                title: 'Otomatik Güncelleme',
                subtitle: 'Arka planda veri yenile',
                value: _otomatikGuncelleme,
                onChanged: (v) => setState(() => _otomatikGuncelleme = v),
              ),
              _RowDivider(),
              _ValueRow(
                icon: Icons.notifications_outlined,
                title: 'Gün Sonu Raporu',
                value: _gunSonuSaati.format(context),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _gunSonuSaati,
                    helpText: 'Rapor saatini seç',
                  );
                  if (picked != null) {
                    setState(() => _gunSonuSaati = picked);
                    final uid = Supabase.instance.client.auth.currentUser?.id;
                    if (uid != null) {
                      await Supabase.instance.client.from('profiles').upsert({
                        'id': uid,
                        'daily_report_hour': picked.hour,
                        'daily_report_minute': picked.minute,
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Kuponlar ─────────────────────────────────────────────────────────
        _SectionLabel('KUPONLAR'),
        const SizedBox(height: 8),
        Container(
          decoration: _sectionDeco(),
          child: Column(
            children: [
              _ValueRow(
                icon: Icons.payments_outlined,
                title: 'Varsayılan Bahis',
                value: '₺100',
                onTap: () => _showComingSoon(context),
              ),
              _RowDivider(),
              _ValueRow(
                icon: Icons.store_outlined,
                title: 'Varsayılan Site',
                value: 'Bilyoner',
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Veriler ──────────────────────────────────────────────────────────
        _SectionLabel('VERİLER'),
        const SizedBox(height: 8),
        Container(
          decoration: _sectionDeco(),
          child: Column(
            children: [
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                title: 'Verileri Temizle',
                subtitle: 'Tüm kuponları sil',
                destructive: true,
                onTap: () => _showComingSoon(context),
              ),
              _RowDivider(),
              _ActionRow(
                icon: Icons.logout_rounded,
                title: 'Çıkış Yap',
                subtitle: 'Hesabından çıkış yap',
                destructive: true,
                onTap: _signOut,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Hakkında ─────────────────────────────────────────────────────────
        _SectionLabel('HAKKINDA'),
        const SizedBox(height: 8),
        Container(
          decoration: _sectionDeco(),
          child: Column(
            children: [
              _ValueRow(
                icon: Icons.info_outline_rounded,
                title: 'Matchly',
                value: '',
                onTap: () => _showComingSoon(context),
              ),
              _RowDivider(),
              const _ValueRow(
                icon: Icons.tag_rounded,
                title: 'Sürüm',
                value: '1.0.0',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textTertiary.withOpacity(0.7),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Row divider ──────────────────────────────────────────────────────────────

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Container(height: 0.5, color: AppColors.border),
    );
  }
}


// ─── Icon container ───────────────────────────────────────────────────────────

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final bool destructive;
  const _RowIcon({required this.icon, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: destructive
            ? AppColors.red.withOpacity(0.10)
            : AppColors.border,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: destructive
              ? AppColors.red.withOpacity(0.18)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Icon(icon, size: 17,
          color: destructive ? AppColors.red.withOpacity(0.80) : AppColors.textSecondary),
    );
  }
}

// ─── Toggle row ───────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _RowIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.80,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.green.withOpacity(0.80),
              inactiveTrackColor: AppColors.border,
              inactiveThumbColor: AppColors.textTertiary,
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Value row ────────────────────────────────────────────────────────────────

class _ValueRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _ValueRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _RowIcon(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            if (value.isNotEmpty) ...[
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
            ],
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Action row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.destructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _RowIcon(icon: icon, destructive: destructive),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: destructive ? AppColors.red : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w400)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}


class _PwField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  const _PwField({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}