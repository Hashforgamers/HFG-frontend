import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/hash_store/widgets/store_page_intro.dart';

void main() {
  testWidgets('shop heading supports narrow screens and larger text', (
    tester,
  ) async {
    for (final width in [320.0, 390.0, 600.0]) {
      await tester.binding.setSurfaceSize(Size(width, 844));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 844),
              textScaler: const TextScaler.linear(1.8),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: StorePageIntro(
                  eyebrow: 'Hash Shop',
                  title: 'Upgrade your game.',
                  subtitle: 'Gear for your setup. Sessions for your next win.',
                  trailing: Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'Layout at width $width');
      expect(find.text('Upgrade your game.'), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('heading keeps its trailing action accessible', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StorePageIntro(
            eyebrow: 'Your bag',
            title: 'Ready when you are.',
            subtitle: 'Review your picks.',
            trailing: IconButton(
              tooltip: 'Open cart',
              onPressed: () => tapped = true,
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Open cart'));
    expect(tapped, isTrue);
  });
}
