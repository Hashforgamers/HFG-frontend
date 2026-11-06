import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/tournaments/data/tournament_models.dart';
import 'package:hash/app/modules/tournaments/data/tournament_payment.dart';

void main() {
  CheckoutOrder? orderOf(Map<String, dynamic> registration) =>
      CheckoutOrder.parse(Registration(registration).checkout);

  test('reads the Razorpay order from a pending registration', () {
    final o = orderOf({
      'status': 'pending_payment',
      'payment': {
        'razorpay_order_id': 'order_ABC',
        'amount': 5000,
        'currency': 'INR',
        'key_id': 'rzp_live_x',
      },
    })!;
    expect(o.id, 'order_ABC');
    expect(o.amountMinor, 5000); // paise, passed to checkout unchanged
    expect(o.key, 'rzp_live_x');
  });

  test('accepts the checkout block and plain order_id', () {
    final o = orderOf({
      'checkout': {'order_id': 'order_XYZ', 'amount_paise': 10000},
    })!;
    expect(o.id, 'order_XYZ');
    expect(o.amountMinor, 10000);
    expect(o.currency, 'INR');
  });

  test('no order means fall back, not a bogus checkout', () {
    expect(orderOf({'status': 'pending_payment'}), isNull);
    // A registration id is not a Razorpay order id.
    expect(orderOf({'payment': {'id': 'b6f1c0de-reg-uuid'}}), isNull);
  });
}
