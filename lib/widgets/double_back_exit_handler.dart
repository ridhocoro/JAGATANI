import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jaga_tani/core/theme/app_colors.dart';

DateTime? _lastBackPressTime;
OverlayEntry? _currentToastEntry;

/// Custom BackButtonDispatcher yang menginterceptsi SEMUA back button event
/// dari sistem Android sebelum GoRouter/Navigator memprosesnya.
class JagaTaniBackButtonDispatcher extends RootBackButtonDispatcher {
  final GlobalKey<NavigatorState> navigatorKey;

  JagaTaniBackButtonDispatcher({required this.navigatorKey});

  @override
  Future<bool> didPopRoute() async {
    // Dapatkan lokasi route saat ini dari GoRouter
    final context = navigatorKey.currentContext;
    if (context == null) {
      return super.didPopRoute();
    }

    // Cek apakah halaman saat ini adalah halaman tab utama
    // Caranya: coba cek apakah Navigator bisa pop (ada history)
    final navigator = navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      // Ada history, biarkan Navigator handle (pop biasa)
      return super.didPopRoute();
    }

    // Tidak ada history (halaman root/tab) → tangani double-back
    final shouldExit = _handleDoubleBackToExit(context);
    if (shouldExit) {
      await SystemNavigator.pop();
    }
    return true; // Selalu return true agar Android tidak langsung close
  }
}

bool _handleDoubleBackToExit(BuildContext context) {
  final now = DateTime.now();
  if (_lastBackPressTime == null ||
      now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
    _lastBackPressTime = now;
    _showExitToast(context);
    return false;
  }
  _removeToast();
  return true;
}

void _removeToast() {
  try {
    _currentToastEntry?.remove();
  } catch (_) {}
  _currentToastEntry = null;
}

void _showExitToast(BuildContext context) {
  _removeToast();

  OverlayState? overlay;
  try {
    overlay = Overlay.maybeOf(context);
  } catch (_) {}

  if (overlay == null) {
    // Fallback: coba dari navigator
    try {
      final nav = Navigator.maybeOf(context);
      if (nav != null) {
        overlay = nav.overlay;
      }
    } catch (_) {}
  }

  if (overlay != null) {
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        bottom: 96,
        left: 28,
        right: 28,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xEE1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.accent, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ketuk lagi untuk keluar',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _currentToastEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentToastEntry == entry) {
        _removeToast();
      }
    });
  } else {
    // Fallback terakhir menggunakan ScaffoldMessenger
    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.removeCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ketuk lagi untuk keluar',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xEE1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.fromLTRB(28, 0, 28, 96),
          ),
        );
      }
    } catch (_) {}
  }
}
