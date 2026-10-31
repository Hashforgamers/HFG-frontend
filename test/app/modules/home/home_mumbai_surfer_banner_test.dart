import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/home/widgets/home_mumbai_surfer_banner.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('fits a narrow phone and opens the Play listing', (tester) async {
    tester.view.physicalSize = const Size(320, 640) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    Uri? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HomeMumbaiSurferBanner(
                openUrl: (uri) async {
                  opened = uri;
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel('Mumbai Surfer. Play now on Google Play.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(HomeMumbaiSurferBanner));
    await tester.pump();
    expect(opened, HomeMumbaiSurferBanner.playStoreUri);
    expect(opened.toString(), contains('id=com.hashforgamers.mumbaisurfer'));
    semantics.dispose();
  });
}
