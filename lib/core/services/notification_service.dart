import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'service_locator.dart';
import 'amplitude_service.dart';

class NotificationService {
  static final _amplitudeService = serviceLocator<AmplitudeService>();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission();

    // Handle notification received when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _amplitudeService.trackPushNotificationReceived(
        title: message.notification?.title ?? '',
        campaignId: message.data['campaign_id'] ?? '',
      );
    });

    // Handle notification clicked
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      await _amplitudeService.trackPushNotificationClicked(
        campaignId: message.data['campaign_id'] ?? '',
        screenTarget: message.data['screen'] ?? '',
      );
      // Navigate to appropriate screen
      if (message.data['screen'] != null) {
        Get.toNamed(message.data['screen']);
      }
    });
  }
} 