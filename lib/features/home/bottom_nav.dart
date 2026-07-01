import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

class BottomNav extends StatelessWidget {
  final VoidCallback onAddPressed;
  final int activeIndex;
  final ValueChanged<int>? onTabChanged;

  const BottomNav({
    super.key,
    required this.onAddPressed,
    this.activeIndex = 0,
    this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.border,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.card.withOpacity(0.95),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: AppColors.border,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _NavTab(
              icon: Icons.confirmation_number_outlined,
              label: t.navMyCoupons,
              active: activeIndex == 0,
              onTap: () => onTabChanged?.call(0),
            ),
            _NavTab(
              icon: Icons.dynamic_feed_rounded,
              label: t.navFeed,
              active: activeIndex == 1,
              onTap: () => onTabChanged?.call(1),
            ),
            // Add button — center slot
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: onAddPressed,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brand,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withOpacity(0.25),
                          blurRadius: 20,
                        ),
                        BoxShadow(
                          color: AppColors.border,
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: AppColors.background,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            _NavTab(
              icon: Icons.bar_chart_rounded,
              label: t.navStatsLabel,
              active: activeIndex == 2,
              onTap: () => onTabChanged?.call(2),
            ),
            _NavTab(
              icon: Icons.settings_outlined,
              label: t.settings,
              active: activeIndex == 3,
              onTap: () => onTabChanged?.call(3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tappable nav tab (wraps NavItem in Expanded + GestureDetector) ───────────

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: NavItem(icon: icon, label: label, active: active),
      ),
    );
  }
}

// ─── Visual nav item (no Expanded — caller controls sizing) ──────────────────

class NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: active ? AppColors.brand : AppColors.textSecondary,
          size: 21,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.brand : AppColors.textSecondary,
            fontSize: 9,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 4 : 0,
          height: active ? 4 : 0,
          decoration: BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
