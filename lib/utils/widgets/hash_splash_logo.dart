import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// The shimmering HASH badge used by the app's splash screens.
///
/// The badge is a 220x220 square at the exact centre of the screen, and the
/// tagline hangs below it without moving it. The native launch screens
/// (iOS LaunchScreen.storyboard, Android launch_background / Android 12
/// splash) draw the same 220pt badge at the same centre, so the hand-off from
/// launch screen to Flutter does not shift or resize the logo.
class HashSplashLogo extends StatelessWidget {
  const HashSplashLogo({super.key});

  static const double size = 220;

  /// The colour badge (`assets/logo.png`) drawn over the exact pixels the
  /// splash badge occupies, so screens after the splash (login) keep the
  /// logo in place. Measured from the two images' badge bounds: logo.png's
  /// badge is 766px wide centred at (511, 507) of 1024; nologoblack.png's is
  /// 694px wide centred at (516, 516).
  static Widget colorBadge() {
    const box = size * 694 / 766;
    const dx = (516 - 512) / 1024 * size - (511 - 512) / 1024 * box;
    const dy = (516 - 512) / 1024 * size - (507 - 512) / 1024 * box;
    return Center(
      child: Transform.translate(
        offset: const Offset(dx, dy),
        child: Image.asset('assets/logo.png', width: box, height: box),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.2),
      highlightColor: Colors.white.withValues(alpha: 0.9),
      period: const Duration(seconds: 2),
      direction: ShimmerDirection.ltr,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/nologoblack.png',
                width: size,
                height: size,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: c.maxHeight / 2 + size / 2 + 10,
              child: Text(
                'LEVEL UP YOUR GAME',
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
