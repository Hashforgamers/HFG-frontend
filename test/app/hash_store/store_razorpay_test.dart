import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/hash_store/data/store_razorpay.dart';

void main() {
  Map<String, dynamic> collection(Map<String, dynamic> data) => {
    'payment_sessions': [
      {'provider_id': 'pp_razorpay_razorpay', 'amount': 5999, 'data': data},
    ],
  };

  test('detects razorpay providers', () {
    expect(isRazorpayProvider('pp_razorpay_razorpay'), isTrue);
    expect(isRazorpayProvider('pp_system_default'), isFalse);
    expect(isRazorpayProvider(null), isFalse);
  });

  test('builds checkout options from the session order', () {
    final o = razorpayOptions(
      collection({
        'id': 'order_abc',
        'amount': 599900,
        'currency': 'inr',
        'key_id': 'rzp_test_x',
      }),
      'pp_razorpay_razorpay',
      email: 'a@b.c',
    )!;
    expect(o['order_id'], 'order_abc');
    expect(o['amount'], 599900);
    expect(o['currency'], 'INR');
    expect(o['key'], 'rzp_test_x');
    expect(o['prefill'], {'email': 'a@b.c'});
  });

  test('Medusa rupee fallback converts once to paise', () {
    expect(
      razorpayOptions(
        collection({'id': 'order_abc'}),
        'pp_razorpay_razorpay',
      )!['amount'],
      599900,
    );
    expect(
      razorpayOptions(
        collection({'id': 'order_abc', 'amount_paise': 12345}),
        'pp_razorpay_razorpay',
      )!['amount'],
      12345,
    );
  });

  test('null without a razorpay order id', () {
    expect(razorpayOptions(collection({}), 'pp_razorpay_razorpay'), isNull);
    expect(razorpayOptions(collection({'id': 'x'}), 'pp_other'), isNull);
  });
}
