import 'package:flutter/material.dart';
import 'app_state.dart';

class AppColors {
  static bool get _isDark => AppState.instance.themeMode == ThemeMode.dark;

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static Color get background => _isDark ? backgroundDark : backgroundLight;
  static Color get surface    => _isDark ? surfaceDark    : surfaceLight;
  static Color get card       => _isDark ? cardDark       : cardLight;
  static Color get cardHigh   => _isDark ? cardHighDark   : cardHighLight;

  // ── Borders ───────────────────────────────────────────────────────────────
  static Color get border     => _isDark ? borderDark     : borderLight;

  // ── Text ──────────────────────────────────────────────────────────────────
  static Color get textPrimary   => _isDark ? textPrimaryDark   : textPrimaryLight;
  static Color get textSecondary => _isDark ? textSecondaryDark : textSecondaryLight;
  static Color get textTertiary  => _isDark ? textTertiaryDark  : textTertiaryLight;

  // ── Accent ────────────────────────────────────────────────────────────────
  static Color get brand => _isDark ? brandDark : brandLight;
  static Color get green => _isDark ? greenDark : greenLight;
  static Color get red   => _isDark ? redDark   : redLight;
  static Color get amber => _isDark ? amberDark : amberLight;
  static Color get gray  => _isDark ? grayDark  : grayLight;

  // ── Light palette ────────────────────────────────────────────────────────
  static const backgroundLight    = Color(0xFFEEF2F7); // slate blue-gray page
  static const surfaceLight       = Color(0xFFE4EAF2); // slightly darker surface
  static const cardLight          = Color(0xFFFFFFFF); // white cards
  static const cardHighLight      = Color(0xFFF5F8FC); // elevated card
  static const borderLight        = Color(0x1A3C5A8C); // 10% slate blue border
  static const textPrimaryLight   = Color(0xFF0F1C2E); // deep navy
  static const textSecondaryLight = Color(0xFF7A8FA8); // slate blue-gray
  static const textTertiaryLight  = Color(0xFFB0BEC8); // light slate
  static const brandLight = Color(0xFF2D4A6E); // deep slate blue
  static const greenLight = Color(0xFF16A34A); // forest green
  static const redLight   = Color(0xFFDC2626); // deep red
  static const amberLight = Color(0xFFA16207); // warm amber
  static const grayLight  = Color(0xFFD0DAE8); // light blue-gray divider

  // ── Dark palette ─────────────────────────────────────────────────────────
  static const backgroundDark    = Color(0xFF0A1118); // near-black navy page
  static const surfaceDark       = Color(0xFF101924); // slightly lighter surface
  static const cardDark          = Color(0xFF17212F); // dark slate cards
  static const cardHighDark      = Color(0xFF1D293A); // elevated card
  static const borderDark        = Color(0x1FFFFFFF); // 12% white border
  static const textPrimaryDark   = Color(0xFFF2F5F9); // near-white
  static const textSecondaryDark = Color(0xFF92A4BD); // slate blue-gray
  static const textTertiaryDark  = Color(0xFF5C6B82); // muted slate
  static const brandDark = Color(0xFF5C8AC6); // brighter slate blue for dark bg
  static const greenDark = Color(0xFF22C55E); // brighter forest green
  static const redDark   = Color(0xFFF87171); // brighter red
  static const amberDark = Color(0xFFD99425); // brighter amber
  static const grayDark  = Color(0xFF293648); // dark blue-gray divider
}
