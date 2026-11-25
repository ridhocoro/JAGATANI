import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

Future<bool> showExitConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black, width: 2.2),
      ),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Text('🌾', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Keluar dari Jaga Tani?',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Apakah Anda yakin ingin keluar dari aplikasi Jaga Tani?',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 1.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: Text(
                  'Batal',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: const BorderSide(color: Colors.black, width: 1.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                child: Text(
                  'Keluar',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
