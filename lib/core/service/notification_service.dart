import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';

class NotificationController extends GetxController {
  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  final segmentService = locator<SegmentSdkService>();

  RxString fcmToken = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // 1) Ask permissions (iOS) + foreground presentation
    final settings = await _fm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    await _fm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // 2) Init local notifications (Android + iOS)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // If using flutter_local_notifications v17+, Darwin* classes are correct.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse r) => _onSelectNotification(r.payload),
    );

    // 3) Android channels (guard for platform)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createAndroidChannels();
    }

    // 4) Message streams
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    // 5) Tokens (wait for APNs on iOS, then get FCM)
    await _initTokens(settings);

    // 6) React to token refresh
    _fm.onTokenRefresh.listen((t) {
      fcmToken.value = t;
      // Send to backend / analytics here
      // segmentService.identifyPushToken(token: t); // if you track it
    });
  }

  Future<void> _initTokens(NotificationSettings settings) async {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    if (isIOS && settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Wait (briefly) for APNs token
      String? apns = await _fm.getAPNSToken();
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (apns == null && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(milliseconds: 250));
        apns = await _fm.getAPNSToken();
      }
    }

    try {
      final token = await _fm.getToken();
      if (token != null && token.isNotEmpty) {
        fcmToken.value = token;
        // Send to backend / analytics here
        // segmentService.identifyPushToken(token: token);
      }
    } catch (_) {
      // Swallow and retry later (e.g., via onTokenRefresh)
    }
  }

  Future<void> _createAndroidChannels() async {
    const contest = AndroidNotificationChannel(
      'contest_channel', 'Contest Notifications',
      description: 'Notifications for contests and tournaments',
      importance: Importance.high,
    );
    const offer = AndroidNotificationChannel(
      'offer_channel', 'Offer Notifications',
      description: 'Promotions, discounts, and deals',
      importance: Importance.high,
    );
    const system = AndroidNotificationChannel(
      'system_channel', 'System Alerts',
      description: 'System notifications and updates',
      importance: Importance.high,
    );

    final androidPlugin = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(contest);
      await androidPlugin.createNotificationChannel(offer);
      await androidPlugin.createNotificationChannel(system);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    // Default values
    final notif = message.notification;
    final title = notif?.title ?? (message.data['title'] ?? '');
    final body  = notif?.body  ?? (message.data['body']  ?? '');
    String channelId = switch (message.data['type']) {
      'contest' => 'contest_channel',
      'offer'   => 'offer_channel',
      _         => 'system_channel',
    };

    // Track receipt
    segmentService.onPushNotificationReceived(
      title: title,
      campaignId: message.data['campaign_id'] ?? '',
    );

    // Android details
    final android = AndroidNotificationDetails(
      channelId,
      channelId == 'contest_channel' ? 'Contest Notifications'
          : channelId == 'offer_channel' ? 'Offer Notifications'
          : 'System Alerts',
      channelDescription: 'Channel for $channelId',
      importance: Importance.max,
      priority: Priority.high,
    );

    // iOS details
    const ios = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );

    final details = NotificationDetails(android: android, iOS: ios);

    _fln.show(
      notif.hashCode,
      title,
      body,
      details,
      payload: message.data['route'] ?? '',
    );
  }

  Future<void> _onSelectNotification(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    segmentService.onPushNotificationClicked(
      campaignId: '',
      screenTarget: payload,
    );

    // Example: Get.toNamed(payload);
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final route = message.data['route'];
    if (route is String && route.isNotEmpty) {
      segmentService.onPushNotificationClicked(
        campaignId: message.data['campaign_id'] ?? '',
        screenTarget: route,
      );
      // Get.toNamed(route);
    }
  }
}
