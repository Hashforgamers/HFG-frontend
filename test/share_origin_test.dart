import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/utils/share_origin.dart';

void main() {
  testWidgets('anchors to the tapped widget, and never returns an empty rect', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(key: key, width: 120, height: 40),
        ),
      ),
    );
    expect(shareOriginRect(key.currentContext), const Rect.fromLTWH(0, 0, 120, 40));

    // no context: the middle of the screen
    final fallback = shareOriginRect();
    expect(fallback.isEmpty, isFalse);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(fallback.center, screen.center(Offset.zero));
  });

  testWidgets('a widget with no size falls back instead of returning an empty rect', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: Center(child: SizedBox(key: key))));
    expect(shareOriginRect(key.currentContext).isEmpty, isFalse);
  });
}
