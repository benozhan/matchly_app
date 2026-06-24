import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
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
  bool _karanlikTema        = true;
  bool _otomatikGuncelleme  = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.instance.getCurrentUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _signOut() async {
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
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.40),
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
        backgroundColor: const Color(0xFF1C1C1E),
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
              border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
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
                            ? _user!.displayName[0]
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
        const SizedBox(height: 26),

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
                builder: (ctx) => GecmisPage(
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
                onChanged: (v) => setState(() => _karanlikTema = v),
              ),
              _RowDivider(),
              _ToggleRow(
                icon: Icons.sync_outlined,
                title: 'Otomatik Güncelleme',
                subtitle: 'Arka planda veri yenile',
                value: _otomatikGuncelleme,
                onChanged: (v) => setState(() => _otomatikGuncelleme = v),
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
      child: Container(height: 0.5, color: Colors.white.withOpacity(0.06)),
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
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: destructive
              ? AppColors.red.withOpacity(0.18)
              : Colors.white.withOpacity(0.08),
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
              inactiveTrackColor: Colors.white.withOpacity(0.08),
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
