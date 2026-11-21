import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/notification_service.dart';

void main() {
  test('old quick-match pushes are dropped, fresh and other pushes kept', () {
    final now = DateTime(2026, 11, 15, 12);
    RemoteMessage m(String type, int minsAgo) => RemoteMessage(
        data: {'type': type}, sentTime: now.subtract(Duration(minutes: minsAgo)));
    expect(isStaleQuickMatch(m('quick_match_waiting', 10), now: now), isTrue);
    expect(isStaleQuickMatch(m('quick_match_waiting', 1), now: now), isFalse);
    expect(isStaleQuickMatch(m('chat', 60), now: now), isFalse);
  });
}
