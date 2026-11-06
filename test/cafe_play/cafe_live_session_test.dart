import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';
import 'package:hash/app/modules/home/models/live_session_booking.dart';

void main() {
  Map<String, dynamic> session(String state) => {
    'id': 'abc',
    'state': state,
    'kind': 'wallet',
    'amount': 6000,
    'minutes': 60,
    'started_at': '2026-10-02T14:00:00Z',
    'ends_at': '2026-10-02T15:00:00Z',
    'checkout': {'cafe_name': 'Example Cafe ', 'console_number': 3},
  };

  test('active cafe session becomes a live session card', () {
    final live = LiveSessionBooking.fromCafeSession(
      CafeSession.fromJson(session('active')),
    );

    expect(live, isNotNull);
    expect(live!.bookingId, 'cafe:abc');
    expect(live.arenaName, 'Example Cafe · PC 3');
    expect(live.vendorId, isEmpty);
    expect(live.endAt.difference(live.startAt), const Duration(hours: 1));
  });

  test('reserved cafe session has no card until the PC starts it', () {
    final live = LiveSessionBooking.fromCafeSession(
      CafeSession.fromJson(session('reserved')),
    );

    expect(live, isNull);
  });
}
