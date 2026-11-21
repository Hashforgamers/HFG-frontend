import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/road_rumble/road_rumble_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('menus lead into a race that responds to touch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: RoadRumbleScreen(web3d: false)),
    );
    await tester.pump(const Duration(milliseconds: 600));

    // 844x390 -> a 519x240 frame scaled 1.625, filling the width.
    Offset game(double x, double y) => Offset(0.3 + x * 1.625, y * 1.625);

    // Title: RACE is the first row; track list: first track.
    await tester.tapAt(game(80, 57));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tapAt(game(80, 57));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('GAS'), findsOneWidget);

    // Hold the throttle through the countdown and a few seconds of racing.
    final gas = await tester.startGesture(const Offset(770, 300));
    for (var i = 0; i < 420; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Slide up to punch without lifting.
    await gas.moveTo(const Offset(770, 170));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gas.up();
    expect(tester.takeException(), isNull);

    // Pause from the HUD corner, then quit back to the title.
    await tester.tapAt(game(8, 12));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('GAS'), findsNothing);
    await tester.tapAt(game(80, 101));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
