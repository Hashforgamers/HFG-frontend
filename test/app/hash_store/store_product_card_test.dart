import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/hash_store/widgets/store_product_card.dart';
import 'package:hash/app/modules/hash_store/widgets/store_ui.dart';

void main() {
  testWidgets('card fits the grid cell on a narrow phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 800),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                StoreProductCard(
                  product: const {
                    'title': 'Naruto Anime Extended Mousepad Deluxe Edition',
                    'price_inr': 12999,
                    'compare_at_price_inr': 16999,
                    'rating_summary': {'count': 1200, 'average': 4.6},
                  },
                  onDetails: () {},
                  onAdd: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('24% OFF'), findsOneWidget);
    expect(find.text('4.6 (1.2K)'), findsOneWidget);
  });

  testWidgets('no MRP means no struck price or discount badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 170,
            height: 250,
            child: StoreProductCard(
              product: const {'title': 'Mouse Pad', 'price_inr': 11},
              onDetails: () {},
              onAdd: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('OFF'), findsNothing);
  });

  test('card price comes from the automatic offer preview', () {
    final offer = storeCardPrice({
      'price_inr': 10,
      'pricing': {
        'original_amount': 10,
        'discount_amount': 3,
        'calculated_amount': 7,
        'discount_percent': 30,
      },
    });
    expect((offer.price, offer.was, offer.off, offer.save), (7, 10, 30, 3));
    final none = storeCardPrice({
      'pricing': {'original_amount': 10, 'calculated_amount': 10},
    });
    expect((none.price, none.off), (10, 0));
    expect(storeCardPrice({'price_inr': 10, 'pricing': null}).price, isNull);
  });

  testWidgets('totals show delivery and platform fee as separate rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StoreTotals(
            cart: {
              'item_subtotal': 100,
              'shipping_total': 60,
              'total': 160,
              'shipping_methods': [
                {
                  'data': {
                    'hash_customer_shipping_paise': 5000,
                    'hash_platform_fee_paise': 1000,
                  },
                },
              ],
            },
          ),
        ),
      ),
    );
    expect(find.text('Hash platform fee (GST inclusive)'), findsOneWidget);
    expect(find.text(storeMoney(50)), findsOneWidget);
    expect(find.text(storeMoney(10)), findsOneWidget);
    expect(find.text(storeMoney(160)), findsOneWidget);
  });
}
