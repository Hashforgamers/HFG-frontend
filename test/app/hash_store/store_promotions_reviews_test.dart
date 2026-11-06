import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _cart({List promotions = const [], num amount = 0}) => {
  'id': 'cart_1',
  'promotions': promotions,
  'items': [
    {
      'adjustments': [
        if (amount != 0) {'code': 'SAVE10', 'amount': amount},
      ],
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    if (locator.isRegistered<SharedPreferences>()) {
      await locator.unregister<SharedPreferences>();
    }
    locator.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
  });
  tearDown(() async => locator.unregister<SharedPreferences>());

  group('couponApplies', () {
    const listed = [
      {'code': 'SAVE10'},
    ];
    test('needs the code listed and a positive adjustment', () {
      expect(
        MedusaStoreService.couponApplies(
          _cart(promotions: listed, amount: 5),
          'SAVE10',
        ),
        isTrue,
      );
    });
    test('listed without an adjustment does not apply', () {
      expect(
        MedusaStoreService.couponApplies(_cart(promotions: listed), 'SAVE10'),
        isFalse,
      );
    });
    test('an adjustment without the listed code does not apply', () {
      expect(
        MedusaStoreService.couponApplies(_cart(amount: 5), 'SAVE10'),
        isFalse,
      );
    });
  });

  test(
    'applyCoupon normalizes the code and reports ineligible carts',
    () async {
      Object? sent;
      final service = MedusaStoreService.forTesting((m, p, d, q) async {
        expect('$m $p', 'POST /store/carts/cart_1/promotions');
        sent = d;
        return {'cart': _cart()};
      });
      final result = await service.applyCoupon('cart_1', '  save10 ');
      expect(sent, {
        'promo_codes': ['SAVE10'],
      });
      expect(result.applied, isFalse);
      expect(result.cart['id'], 'cart_1');
    },
  );

  test('removeCoupon sends the JSON body', () async {
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      expect('$m $p', 'DELETE /store/carts/cart_1/promotions');
      expect(d, {
        'promo_codes': ['SAVE10'],
      });
      return {'cart': _cart()};
    });
    await service.removeCoupon('cart_1', 'SAVE10');
  });

  test('saveReview sends revision only for edits and never identity', () async {
    final bodies = <Object?>[];
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      expect('$m $p', 'POST /store/hash/reviews');
      bodies.add(d);
      return {
        'review': {'id': 'hr_1', 'status': 'pending'},
      };
    });
    await service.saveReview(
      productId: 'prod_1',
      orderId: 'order_1',
      rating: 4,
      title: ' Good ',
      body: ' Worked well for me. ',
    );
    await service.saveReview(
      productId: 'prod_1',
      orderId: 'order_1',
      rating: 5,
      title: '',
      body: 'Worked well for me.',
      revision: 3,
    );
    expect(bodies.first, {
      'product_id': 'prod_1',
      'order_id': 'order_1',
      'rating': 4,
      'title': 'Good',
      'body': 'Worked well for me.',
    });
    expect((bodies.last as Map)['revision'], 3);
  });

  test('withdrawReview sends the revision', () async {
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      expect('$m $p', 'DELETE /store/hash/reviews/hr_1');
      expect(d, {'revision': 2});
      return {
        'review': {'id': 'hr_1', 'status': 'withdrawn', 'revision': 3},
      };
    });
    expect((await service.withdrawReview('hr_1', 2))['revision'], 3);
  });
}
