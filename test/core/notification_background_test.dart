import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/notification_service.dart';

void main() {
  test('pushes the OS already shows are not shown again', () {
    const shown = RemoteMessage(
      notification: RemoteNotification(title: 'Match ready', body: 'Join now'),
      data: {'type': 'contest'},
    );
    expect(needsLocalNotificationInBackground(shown), isFalse);
  });

  test('data-only pushes still get a local notification', () {
    const dataOnly = RemoteMessage(
      data: {'type': 'chat', 'sender_name': 'Bhanu', 'message': 'hi'},
    );
    expect(needsLocalNotificationInBackground(dataOnly), isTrue);
  });
}
