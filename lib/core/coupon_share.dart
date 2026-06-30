import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/coupon.dart';
import 'app_colors.dart';

// TODO(deep-links): Replace clipboard copy with native share sheet
//   (share_plus) once matchly.app/coupon/{sharedId} routing is live.
// TODO(live-shared-coupon): When a recipient opens the link, show a live
//   shared coupon screen with real-time selection status — requires
//   WebSocket feed keyed on sharedId.
// TODO(user-profiles): Link sharedId to the sharer's profile page so
//   recipients can follow them.
// TODO(friends-following): Send a push notification to followers when a
//   new coupon is shared (requires follow graph + FCM/APNs integration).

class CouponShare {
  CouponShare._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Copies share text to clipboard and shows a top toast.
  ///
  /// Creates a new random [sharedId] if the coupon has none, or reuses the
  /// existing one. Returns the [sharedId] that was used so the caller can
  /// persist it back to the coupon model.
  static Future<String> share(BuildContext context, Coupon coupon) async {
    final id   = coupon.sharedId ?? coupon.id ?? _generateId();
    final text = buildShareText(coupon, sharedId: id);
    await SharePlus.instance.share(ShareParams(text: text));
    return id;
  }

  /// Generates the share text for [coupon] using [sharedId] as the link key.
  ///
  /// Intentionally minimal — the link itself will open a live shared coupon
  /// screen once deep link routing is implemented server-side.
  // TODO(deep-links): matchly.app/coupon/{sharedId} should resolve to a live
  //   shared coupon screen showing real-time selection status updates.
  static String buildShareText(Coupon coupon, {required String sharedId}) {
    final matches = coupon.matches.map((m) => '${m.teams} — ${m.selection}').join('\n');
    return '🎯 ${coupon.title}\n$matches\n\nMatchly\'de takip et 👇\nhttps://matchlyweb.vercel.app/coupon/$sharedId';
  }

  // ── ID generation ──────────────────────────────────────────────────────────

  /// Generates a cryptographically random 16-char hex string (8 bytes).
  ///
  /// Replace with a server-issued UUID once user accounts exist.
  static String _generateId() {
    final rng = Random.secure();
    return List.generate(
      8,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  // ── Top toast ──────────────────────────────────────────────────────────────

  static void showTopToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

// ─── Top toast widget ─────────────────────────────────────────────────────────

class _TopToast extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _TopToast({required this.message, required this.onDismiss});

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2400), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _ctrl.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D4A6E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.green,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
