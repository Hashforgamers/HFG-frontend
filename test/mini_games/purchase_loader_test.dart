import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/utils/widgets/game_button.dart';

void main() {
  testWidgets('a loading GameButton shows a spinner instead of its icon', (tester) async {
    Widget app(bool loading) => MaterialApp(
      home: Scaffold(
        body: GameButton(label: 'Buy · 500', icon: Icons.shopping_bag_rounded, loading: loading),
      ),
    );
    await tester.pumpWidget(app(false));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.shopping_bag_rounded), findsWidgets);
    await tester.pumpWidget(app(true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_rounded), findsNothing);
  });
}
