import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/app/modules/hash_store/cubit/hash_store_cart_cubit.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_checkout_page.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_order_page.dart';
import 'package:hash/app/modules/hash_store/pages/hash_store_orders_view.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  for (final sellerPaid in [false, true]) {
    test(
      'calculates ${sellerPaid ? 'seller' : 'customer'} delivery and excludes legacy free option',
      () async {
        final calls = <String>[];
        final service = MedusaStoreService.forTesting((
          method,
          path,
          data,
          query,
        ) async {
          calls.add('$method $path');
          if (path.endsWith('/delivery')) {
            return {'payer': sellerPaid ? 'seller' : 'customer'};
          }
          if (path == '/store/shipping-options') {
            expect(query, {'cart_id': 'cart_1'});
            return {
              'shipping_options': [
                {'id': 'legacy', 'provider_id': 'manual', 'amount': 0},
                {'id': 'so_hash', 'provider_id': 'hash_delivery_hash_delivery'},
              ],
            };
          }
          expect(path, '/store/shipping-options/so_hash/calculate');
          expect(method, 'POST');
          expect(data, {'cart_id': 'cart_1', 'data': {}});
          return {
            'shipping_option': {'amount': sellerPaid ? 0 : 89.5},
          };
        });
        final delivery = await service.deliveryOptions('cart_1');
        expect(delivery.sellerPaid, sellerPaid);
        expect(delivery.options.single['amount'], sellerPaid ? 0 : 89.5);
        expect(delivery.options.single['id'], 'so_hash');
        expect(calls.length, 3);
      },
    );
  }

  test('missing package data blocks customer quoting', () async {
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      expect(p.endsWith('/delivery'), isTrue);
      return {
        'payer': 'customer',
        'missing_package_product_ids': ['prod_1'],
      };
    });
    await expectLater(
      service.deliveryOptions('cart_1'),
      throwsA(isA<StoreException>()),
    );
  });

  test(
    'no applicable option never falls back to legacy free shipping',
    () async {
      final service = MedusaStoreService.forTesting(
        (m, p, d, q) async => p.endsWith('/delivery')
            ? {'payer': 'customer'}
            : {
                'shipping_options': [
                  {'id': 'old', 'provider_id': 'manual', 'amount': 0},
                ],
              },
      );
      expect((await service.deliveryOptions('cart_1')).options, isEmpty);
    },
  );

  test('missing calculated amount cannot become free shipping', () async {
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      if (p.endsWith('/delivery')) return {'payer': 'customer'};
      if (p.endsWith('/calculate')) return {'shipping_option': {}};
      return {
        'shipping_options': [
          {'id': 'so_1', 'provider_id': 'hash_delivery_hash_delivery'},
        ],
      };
    });
    await expectLater(
      service.deliveryOptions('cart_1'),
      throwsA(isA<StoreException>()),
    );
  });

  test('selection sends no price, quote id or payer override', () async {
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      expect(m, 'POST');
      expect(p, '/store/carts/cart_1/shipping-methods');
      expect(d, {'option_id': 'so_hash', 'data': {}});
      return {
        'cart': {'id': 'cart_1', 'shipping_total': 89, 'total': 1089},
      };
    });
    expect((await service.selectShipping('cart_1', 'so_hash'))['total'], 1089);
  });

  test(
    'paid cart survives reopening and blocks new payment or shipping',
    () async {
      var requests = 0;
      final service = MedusaStoreService.forTesting((m, p, d, q) async {
        requests++;
        return {};
      });
      await service.rememberPaidCart('cart_1');
      expect(service.paymentAwaitingCompletion('cart_1'), isTrue);
      final reopened = MedusaStoreService.forTesting((m, p, d, q) async {
        requests++;
        return {};
      });
      expect(reopened.paymentAwaitingCompletion('cart_1'), isTrue);
      await expectLater(
        reopened.selectShipping('cart_1', 'so_1'),
        throwsA(isA<StoreException>()),
      );
      await expectLater(
        reopened.startPayment({'id': 'cart_1'}, 'razorpay'),
        throwsA(isA<StoreException>()),
      );
      await expectLater(
        reopened.setQuantity('cart_1', 'item_1', 2),
        throwsA(isA<StoreException>()),
      );
      expect(requests, 0);
    },
  );

  test(
    'completion timeout never substitutes an unrelated latest order',
    () async {
      final service = MedusaStoreService.forTesting((m, p, d, q) async {
        expect(p, '/store/carts/cart_1/complete');
        throw const StoreException('timeout', isTimeout: true);
      });
      await expectLater(
        service.completeCart('cart_1'),
        throwsA(isA<StoreException>()),
      );
    },
  );

  testWidgets(
    'changed total needs acceptance; completion retries never reopen payment',
    (tester) async {
      var selections = 0;
      var sessions = 0;
      var payments = 0;
      var completions = 0;
      final cart = <String, dynamic>{
        'id': 'cart_1',
        'total': 100,
        'email': 'customer@example.com',
        'items': [],
        'shipping_address': {
          'first_name': 'Test',
          'last_name': 'Customer',
          'address_1': 'Test street',
          'city': 'Mumbai',
          'province': 'Maharashtra',
          'postal_code': '400001',
          'phone': '9000000000',
        },
      };
      final service = MedusaStoreService.forTesting((m, p, d, q) async {
        if (p.endsWith('/addresses')) return {'addresses': []};
        if (p.endsWith('/delivery')) return {'payer': 'customer'};
        if (p == '/store/shipping-options') {
          return {
            'shipping_options': [
              {
                'id': 'so_1',
                'name': 'Surface delivery',
                'provider_id': 'hash_delivery_hash_delivery',
              },
            ],
          };
        }
        if (p.endsWith('/calculate')) {
          return {
            'shipping_option': {'amount': 10},
          };
        }
        if (p == '/store/payment-providers') {
          return {
            'payment_providers': [
              {'id': 'pp_razorpay_razorpay'},
            ],
          };
        }
        if (p.endsWith('/shipping-methods')) {
          selections++;
          return {
            'cart': {
              ...cart,
              'shipping_total': selections == 1 ? 10 : 15,
              'total': selections == 1 ? 110 : 115,
            },
          };
        }
        if (p == '/store/payment-collections') {
          return {
            'payment_collection': {'id': 'paycol_1'},
          };
        }
        if (p.endsWith('/payment-sessions')) {
          sessions++;
          return {
            'payment_collection': {
              'payment_sessions': [
                {
                  'provider_id': 'pp_razorpay_razorpay',
                  'data': {
                    'id': 'order_test',
                    'amount': 11500,
                    'key_id': 'test_key',
                  },
                },
              ],
            },
          };
        }
        if (p.endsWith('/complete')) {
          completions++;
          throw const StoreException(
            'Please retry confirmation.',
            isTimeout: true,
          );
        }
        expect(p, '/store/carts/cart_1');
        return {'cart': cart};
      });
      final cubit = HashStoreCartCubit()..replace(cart);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: HashStoreCheckoutPage(
              store: service,
              pay: (options) async {
                expect(options['amount'], 11500);
                payments++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to delivery'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Surface delivery'));
      await tester.tap(find.text('Surface delivery'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Place order'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Your delivery total changed.'),
        findsOneWidget,
      );
      expect(sessions, 0);
      await tester.tap(find.text('Place order'));
      await tester.pumpAndSettle();
      expect(payments, 1);
      expect(completions, 1);
      await tester.tap(find.text('Confirm paid order'));
      await tester.pumpAndSettle();
      expect(completions, 2);
      expect(payments, 1);
      expect(sessions, 1);
      expect(selections, 3);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    },
  );

  test('timeline sorts UTC timestamps and retains repeated stages', () {
    final entries = storeTimeline({
      'timeline': [
        {'id': '2', 'status': 'shipped', 'at': '2026-10-28T09:00:00Z'},
        {'id': '1', 'status': 'shipped', 'at': '2026-10-28T08:00:00Z'},
        {'id': '3', 'status': 'shipped', 'at': '2026-10-28T09:00:00Z'},
      ],
    });
    expect(entries.map((e) => e['id']), ['1', '2', '3']);
    expect(storeTrackingUri('http://courier.example'), isNull);
    expect(storeTrackingUri('javascript:alert(1)'), isNull);
    expect(storeTrackingUri('https://courier.example/track/123'), isNotNull);
  });

  testWidgets(
    'carrier delivery remains awaiting OTP, hold and notes stay visible',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StoreOrderTracker(
                status: {
                  'status': 'shipped',
                  'on_hold': true,
                  'timeline': [
                    {
                      'status': 'delivery_attempted',
                      'note': '<b>Try tomorrow</b>',
                    },
                    {'status': 'carrier_delivered'},
                  ],
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('Order on hold — under review'), findsOneWidget);
      expect(find.text('<b>Try tomorrow</b>'), findsOneWidget);
      expect(
        find.text('Courier reports delivered — awaiting OTP'),
        findsOneWidget,
      );
      expect(find.text('Delivery confirmed'), findsNothing);
    },
  );

  test('order rows show the Hash stage, with hold and cancellation first', () {
    expect(storeTrackingStatus({'status': 'shipped'}).$1, 'Shipped');
    expect(
      storeTrackingStatus({'status': 'shipped', 'on_hold': true}).$1,
      'On hold',
    );
    expect(
      storeTrackingStatus({
        'status': 'shipped',
        'on_hold': true,
        'cancellation': {'status': 'requested'},
      }).$1,
      'Cancellation requested',
    );
    expect(
      storeTrackingStatus({'status': 'preparing', 'kind': 'service'}).$1,
      'Preparing',
    );
  });

  test('product and service stages use their own labels', () {
    expect(storeTrackingLabel('placed'), 'New Order');
    expect(storeTrackingLabel('preparing'), 'Processing');
    expect(storeTrackingLabel('ready_to_ship'), 'Ready to Ship');
    expect(storeTrackingLabel('preparing', 'service'), 'Preparing');
    expect(
      storeTrackingLabel('ready_for_service', 'service'),
      'Ready for service',
    );
  });

  testWidgets('cancellation request shows immediately and blocks the OTP', (
    tester,
  ) async {
    Map<String, dynamic>? cancellation;
    Object? sent;
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      if (p.endsWith('/cancellation')) {
        sent = d;
        cancellation = {'status': 'requested', 'source': 'customer'};
        return {'cancellation': cancellation};
      }
      if (p.startsWith('/store/hash/')) {
        return {
          'order': {'paid': true, 'completion_eligible': true},
          'tracking': {
            'status': 'shipped',
            if (cancellation != null) 'cancellation': cancellation,
          },
        };
      }
      return {
        'order': {'id': 'order_1', 'items': [], 'total': 100},
      };
    });
    await tester.pumpWidget(
      MaterialApp(
        home: HashStoreOrderPage(orderId: 'order_1', store: service),
      ),
    );
    await tester.pump();
    expect(find.text('Show completion OTP'), findsOneWidget);
    await tester.ensureVisible(find.text('Request cancellation'));
    await tester.tap(find.text('Request cancellation'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ordered by mistake');
    await tester.pump();
    await tester.tap(find.text('Request cancellation').last);
    await tester.pumpAndSettle();
    expect(sent, {'reason': 'Ordered by mistake'});
    expect(find.text('Cancellation requested'), findsOneWidget);
    expect(find.text('Show completion OTP'), findsNothing);
    expect(find.textContaining('refunded'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('polling stops in background and refreshes on resume', (
    tester,
  ) async {
    var trackingReads = 0;
    final service = MedusaStoreService.forTesting((m, p, d, q) async {
      if (p.startsWith('/store/hash/')) {
        trackingReads++;
        return {
          'order': {'paid': true},
          'tracking': {
            'status': trackingReads > 1 ? 'delivery_attempted' : 'shipped',
          },
        };
      }
      return {
        'order': {'id': 'order_1', 'items': [], 'total': 100},
      };
    });
    await tester.pumpWidget(
      MaterialApp(
        home: HashStoreOrderPage(orderId: 'order_1', store: service),
      ),
    );
    await tester.pump();
    expect(trackingReads, 1);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(trackingReads, 2);
    expect(find.text('Delivery attempted'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 90));
    expect(trackingReads, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(trackingReads, 3);
    await tester.pumpWidget(const SizedBox());
  });
}
