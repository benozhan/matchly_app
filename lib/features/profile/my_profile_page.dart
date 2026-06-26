import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_state.dart';
import '../../core/app_state.dart';
import '../../models/coupon.dart';
import '../../services/auth_service.dart';

class MyProfilePage extends StatelessWidget {
  final AppUser? user;
  final List<Coupon> coupons;

  const MyProfilePage({
    super.key,
    required this.user,
    required this.coupons,
  });

  @override
  Widget build(BuildContext context) {
    final username = user?.username ?? 'user';
    final displayName = user?.displayName ?? username;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    final totalCoupons = coupons.length;
    final activeCoupons =
        coupons.where((c) => c.status == CouponStatus.pending).length;

    var totalStake = 0.0;
    var totalPotential = 0.0;

    for (final coupon in coupons) {
      final stakeMatch =
          RegExp(r'₺(\d+(?:[.,]\d+)?)').firstMatch(coupon.stake);
      final potentialMatch =
          RegExp(r'₺(\d+(?:[.,]\d+)?)').firstMatch(coupon.potential);

      if (stakeMatch != null) {
        totalStake +=
            double.tryParse(stakeMatch.group(1)!.replaceAll(',', '.')) ?? 0;
      }

      if (potentialMatch != null) {
        totalPotential +=
            double.tryParse(potentialMatch.group(1)!.replaceAll(',', '.')) ?? 0;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => AppState.instance.toggleLocale(),
                      icon: Text(
                        Localizations.localeOf(context).languageCode == 'tr' ? 'EN' : 'TR',
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => AppState.instance.toggleTheme(),
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brand,
                          AppColors.brand.withOpacity(0.60),
                        ],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStatCard(
                        label: 'Kupon',
                        value: '$totalCoupons',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileStatCard(
                        label: 'Aktif',
                        value: '$activeCoupons',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStatCard(
                        label: 'Toplam Bahis',
                        value: '₺${totalStake.toInt()}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProfileStatCard(
                        label: 'Beklenti',
                        value: '₺${totalPotential.toInt()}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Profil sistemi Supabase’e taşınıyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

class _ProfileStatCard extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}