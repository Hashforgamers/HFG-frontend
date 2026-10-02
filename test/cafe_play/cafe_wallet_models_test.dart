import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';

void main() {
  test('parses a wallet list page', () {
    final page = CafePage.fromJson({
      'items': [
        {
          'vendor_id': 12,
          'cafe_name': 'Example Gaming Cafe',
          'currency': 'INR',
          'balance': 50000,
          'reserved': 10000,
          'available_balance': 40000,
          'topup_at_cafe_only': true,
        },
      ],
      'next_cursor': 12,
    }, CafeWallet.fromJson);

    expect(page.nextCursor, 12);
    final w = page.items.single;
    expect(w.vendorId, 12);
    expect(w.balance, 50000);
    expect(w.reserved, 10000);
    expect(w.availableBalance, 40000);
  });

  test('empty page has no cursor', () {
    final page = CafePage.fromJson({
      'items': [],
      'next_cursor': null,
    }, CafeWallet.fromJson);
    expect(page.items, isEmpty);
    expect(page.nextCursor, isNull);
  });

  test('parses history entries', () {
    final page = CafePage.fromJson({
      'vendor_id': 12,
      'currency': 'INR',
      'items': [
        {
          'id': 105,
          'kind': 'capture',
          'amount': -10000,
          'balance_after': 40000,
          'reserved_after': 0,
          'method': null,
          'session_id': 'x',
          'reversal_of': null,
          'created_at': '2026-09-29T10:00:00Z',
        },
        {
          'id': 104,
          'kind': 'topup',
          'amount': 50000,
          'balance_after': 50000,
          'reserved_after': 0,
          'method': 'cash',
          'created_at': '2026-09-29T09:30:00Z',
        },
        {'id': 103, 'kind': 'reserve', 'amount': 0, 'reserved_after': 10000},
      ],
      'next_cursor': 103,
    }, CafeWalletEntry.fromJson);

    expect(page.nextCursor, 103);
    final [capture, topup, reserve] = page.items;
    expect(capture.kind, CafeWalletEntryKind.capture);
    expect(capture.amount, -10000);
    expect(capture.label, 'Gaming charge');
    expect(capture.createdAt!.isUtc, isFalse);
    expect(topup.methodLabel, 'Cash');
    expect(topup.label, 'Added at cafe');
    expect(reserve.isHold, isTrue);
    expect(reserve.reservedAfter, 10000);
  });
}
