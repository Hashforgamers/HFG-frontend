import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/hash_store/widgets/neon_switch.dart';

void main() {
  Widget bar(int index) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 56,
        child: NeonSwitchFx(
          index: index,
          count: 3,
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: NeonFlip(slot: i, child: Text('$i')),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  testWidgets('switching tabs plays the effect and settles', (tester) async {
    await tester.pumpWidget(bar(0));
    await tester.pumpWidget(bar(2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('NeonTabBar follows a DefaultTabController', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              bottom: NeonTabBar(
                TabBar(
                  tabs: neonTabs(const [Tab(text: 'A'), Tab(text: 'B')]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('B'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });
}
