import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_colors.dart';

/// Kasa (başlangıç bakiyesi) girme/düzenleme dialog'u.
/// Kaydedilirse girilen tutarı, iptal/daha sonra denirse `null` döner.
/// Değeri Supabase'e yazmak çağıranın sorumluluğu (AuthService.updateStartingBalance).
Future<double?> showStartingBalanceDialog(
  BuildContext context, {
  double? current,
  bool allowLater = true,
}) {
  final t = AppLocalizations.of(context)!;
  final controller = TextEditingController(
    text: (current != null && current > 0) ? current.toStringAsFixed(0) : '',
  );

  return showDialog<double>(
    context: context,
    barrierDismissible: allowLater,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) {
        String? error;

        void trySave() {
          final raw = controller.text.trim().replaceAll(',', '.');
          final value = double.tryParse(raw);
          if (value == null || value <= 0) {
            setDialogState(() => error = t.startingBalanceInvalidError);
            return;
          }
          Navigator.of(dialogCtx).pop(value);
        }

        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            t.startingBalanceTitle,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.startingBalanceBody,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onSubmitted: (_) => trySave(),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: '₺ ',
                  prefixStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  hintText: t.startingBalanceHint,
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 15),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: TextStyle(color: AppColors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            if (allowLater)
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(
                  t.startingBalanceLater,
                  style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600),
                ),
              ),
            TextButton(
              onPressed: trySave,
              child: Text(
                t.saveLabel,
                style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    ),
  );
}
