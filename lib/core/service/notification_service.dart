import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

class NotificationController extends GetxController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final segmentService = locator<SegmentSdkService>();

  RxString fcmToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeNotification();
    _getFCMToken();
  }

  Future<void> _initializeNotification() async {
    await _firebaseMessaging.requestPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onSelectNotification(response.payload);
      },
    );

    // CREATE CUSTOM CHANNELS
    _createNotificationChannels();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageNavigation(message);
    });
  }

  void _createNotificationChannels() async {
    const AndroidNotificationChannel contestChannel = AndroidNotificationChannel(
      'contest_channel', // ID
      'Contest Notifications', // Name
      description: 'Notifications for contests and tournaments',
      importance: Importance.high,
    );

    const AndroidNotificationChannel offerChannel = AndroidNotificationChannel(
      'offer_channel',
      'Offer Notifications',
      description: 'Promotions, discounts, and deals',
      importance: Importance.high,
    );

    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      'system_channel',
      'System Alerts',
      description: 'System notifications and updates',
      importance: Importance.high,
    );

    final AndroidFlutterLocalNotificationsPlugin androidPlugin =
    _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()!;

    await androidPlugin.createNotificationChannel(contestChannel);
    await androidPlugin.createNotificationChannel(offerChannel);
    await androidPlugin.createNotificationChannel(systemChannel);
  }


  Future<void> _getFCMToken() async {
    fcmToken.value = await _firebaseMessaging.getToken() ?? '';
    // TODO: Send this token to your backend server for targeted notifications
  }

  void _showLocalNotification(RemoteMessage message) {
    String channelId = 'system_channel'; // Default channel
    if (message.data.containsKey('type')) {
      switch (message.data['type']) {
        case 'contest':
          channelId = 'contest_channel';
          break;
        case 'offer':
          channelId = 'offer_channel';
          break;
        case 'system':
          channelId = 'system_channel';
          break;
      }
    }

    // Track push notification received event
    segmentService.onPushNotificationReceived(
      title: message.notification?.title ?? '',
      campaignId: message.data['campaign_id'] ?? '',
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'contest_channel' ? 'Contest Notifications'
          : channelId == 'offer_channel' ? 'Offer Notifications'
          : 'System Alerts',
      channelDescription: 'Channel for $channelId',
      importance: Importance.max,
      priority: Priority.high,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    _flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data['route'] ?? '',
    );
  }


  Future<void> _onSelectNotification(String? payload) async {
    if (payload != null) {
      
      // Track push notification clicked event
      segmentService.onPushNotificationClicked(
        campaignId: '',
        screenTarget: payload,
      );
      
      // Handle navigation based on payload
      // e.g., Get.toNamed(payload);
    }
  }

  void _handleMessageNavigation(RemoteMessage message) {
    if (message.data.containsKey('route')) {
      String route = message.data['route'];
      
      // Track push notification clicked event
      segmentService.onPushNotificationClicked(
        campaignId: message.data['campaign_id'] ?? '',
        screenTarget: route,
      );
      
      Get.toNamed(route);
    }
  }
}
