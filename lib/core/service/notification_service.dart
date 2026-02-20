import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hash/app/modules/live/views/live_stream_screen.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/firebase_options.dart';

const AndroidNotificationChannel _contestChannel = AndroidNotificationChannel(
  'contest_channel',
  'Contest Notifications',
  description: 'Notifications for contests and tournaments',
  importance: Importance.high,
);
const AndroidNotificationChannel _offerChannel = AndroidNotificationChannel(
  'offer_channel',
  'Offer Notifications',
  description: 'Promotions, discounts, and deals',
  importance: Importance.high,
);
const AndroidNotificationChannel _systemChannel = AndroidNotificationChannel(
  'system_channel',
  'System Alerts',
  description: 'System notifications and updates',
  importance: Importance.high,
);
const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
  'chat_channel',
  'Chat Messages',
  description: 'Notifications for incoming chat messages',
  importance: Importance.high,
);

String _channelIdFromType(String? type) {
  return switch (type) {
    'contest' => _contestChannel.id,
    'offer' => _offerChannel.id,
    'chat' => _chatChannel.id,
    _ => _systemChannel.id,
  };
}

String _channelNameFromId(String channelId) {
  return switch (channelId) {
    'contest_channel' => 'Contest Notifications',
    'offer_channel' => 'Offer Notifications',
    'chat_channel' => 'Chat Messages',
    _ => 'System Alerts',
  };
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final fln = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await fln.initialize(initSettings);

  final androidPlugin = fln
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(_contestChannel);
    await androidPlugin.createNotificationChannel(_offerChannel);
    await androidPlugin.createNotificationChannel(_systemChannel);
    await androidPlugin.createNotificationChannel(_chatChannel);
  }

  final notif = message.notification;
  final title = notif?.title ?? (message.data['title'] ?? '').toString();
  final body = notif?.body ?? (message.data['body'] ?? '').toString();
  if (title.isEmpty && body.isEmpty) return;

  final channelId = _channelIdFromType(message.data['type']?.toString());
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      _channelNameFromId(channelId),
      channelDescription: 'Channel for $channelId',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  await fln.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
    payload: message.data['route']?.toString() ?? '',
  );
}

class NotificationController extends GetxController {
  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
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
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) Init local notifications (Android + iOS)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // If using flutter_local_notifications v17+, Darwin* classes are correct.
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse r) =>
          _onSelectNotification(r.payload),
    );

    // 3) Android channels (guard for platform)
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _createAndroidChannels();
    }

    // 4) Message streams
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
    unawaited(_handleInitialMessage());

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

    if (isIOS &&
        settings.authorizationStatus == AuthorizationStatus.authorized) {
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
    final androidPlugin = _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_contestChannel);
      await androidPlugin.createNotificationChannel(_offerChannel);
      await androidPlugin.createNotificationChannel(_systemChannel);
      await androidPlugin.createNotificationChannel(_chatChannel);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    // Default values
    final notif = message.notification;
    final title = notif?.title ?? (message.data['title'] ?? '');
    final body = notif?.body ?? (message.data['body'] ?? '');
    final channelId = _channelIdFromType(message.data['type']?.toString());

    // Track receipt
    segmentService.onPushNotificationReceived(
      title: title,
      campaignId: message.data['campaign_id'] ?? '',
    );

    // Android details
    final android = AndroidNotificationDetails(
      channelId,
      _channelNameFromId(channelId),
      channelDescription: 'Channel for $channelId',
      importance: Importance.max,
      priority: Priority.high,
    );

    // iOS details
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
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

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _fm.getInitialMessage();
    if (initialMessage == null) return;
    _handleMessageNavigation(initialMessage);
  }

  Future<void> _onSelectNotification(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    if (payload.startsWith('chat:')) {
      final roomId = payload.replaceFirst('chat:', '').trim();
      if (roomId.isNotEmpty) {
        Get.toNamed(AppRoutes.CHAT, arguments: {'roomId': roomId});
      } else {
        Get.toNamed(AppRoutes.CHAT);
      }
      return;
    }

    if (payload.startsWith('live:')) {
      final streamId = payload.replaceFirst('live:', '').trim();
      if (streamId.isNotEmpty) {
        Get.to(() => LiveStreamScreen(streamId: streamId));
      }
      return;
    }

    segmentService.onPushNotificationClicked(
      campaignId: '',
      screenTarget: payload,
    );

    if (payload.startsWith('/')) {
      Get.toNamed(payload);
    }
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

  Future<void> showChatNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'chat_channel',
      'Chat Messages',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
      threadIdentifier: 'chat_messages',
    );

    final details = const NotificationDetails(android: android, iOS: ios);
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload ?? AppRoutes.CHAT,
    );
  }

  Future<void> showLiveNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'contest_channel',
      'Contest Notifications',
      channelDescription: 'Notifications for contests and tournaments',
      importance: Importance.max,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(android: android, iOS: ios);
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload ?? '',
    );
  }
}
