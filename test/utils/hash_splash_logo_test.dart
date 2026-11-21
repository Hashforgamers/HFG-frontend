import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/hash_splash_logo.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // The native launch screens draw a 220pt badge at the exact screen centre;
  // the Flutter splash must put it in the same place at the same size.
  for (final size in const [Size(393, 852), Size(360, 800), Size(820, 1180)]) {
    testWidgets('badge is 220x220 at the centre of $size', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(backgroundColor: Colors.black, body: HashSplashLogo()),
        ),
      );
      final badge = tester.getRect(find.byType(Image));
      expect(badge.size, const Size(220, 220));
      expect(badge.center, Offset(size.width / 2, size.height / 2));
      // Tagline sits below the badge, not over it.
      expect(
        tester.getRect(find.text('LEVEL UP YOUR GAME')).top,
        greaterThan(badge.bottom),
      );
    });
  }

  testWidgets('login colour badge covers the splash badge pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [const HashSplashLogo(), HashSplashLogo.colorBadge()],
          ),
        ),
      ),
    );
    final images = find.byType(Image);
    final white = tester.getRect(images.at(0));
    final colour = tester.getRect(images.at(1));
    // Measured artwork bounds inside each 1024px image.
    final a = _badge(white, const Rect.fromLTRB(169, 186, 864, 847));
    final b = _badge(colour, const Rect.fromLTRB(128, 132, 895, 883));
    expect((a.center - b.center).distance, lessThan(1.0));
    expect((a.width - b.width).abs(), lessThan(1.0));
  });
}

/// Where the badge artwork itself (not its transparent padding) lands.
Rect _badge(Rect image, Rect boundsIn1024) => Rect.fromLTRB(
  image.left + boundsIn1024.left / 1024 * image.width,
  image.top + boundsIn1024.top / 1024 * image.height,
  image.left + boundsIn1024.right / 1024 * image.width,
  image.top + boundsIn1024.bottom / 1024 * image.height,
);
