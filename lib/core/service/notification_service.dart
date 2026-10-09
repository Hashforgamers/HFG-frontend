import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/live/views/live_stream_screen.dart';
import 'package:hash/app/modules/notifications/controllers/app_notifications_controller.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/core/service/crash_reporting.dart';
import 'package:hash/core/service/push_router.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/deeplink_service.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: iosInit,
  );
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
  final type = (message.data['type'] ?? '').toString();
  String title = notif?.title ?? (message.data['title'] ?? '').toString();
  String body = notif?.body ?? (message.data['body'] ?? '').toString();
  final roomId = (message.data['room_id'] ?? message.data['chat_room_id'] ?? '')
      .toString()
      .trim();
  if (type == 'new_notification') {
    if (title.trim().isEmpty) {
      title = 'Team Invite';
    }
    if (body.trim().isEmpty) {
      final inviteStatus = (message.data['invite_status'] ?? 'pending')
          .toString()
          .toLowerCase();
      body = inviteStatus == 'accepted'
          ? 'Your team invite was accepted.'
          : inviteStatus == 'rejected'
          ? 'Your team invite was rejected.'
          : 'You have a new team invite.';
    }
  } else if (type == 'chat') {
    if (title.trim().isEmpty) {
      title =
          (message.data['sender_name'] ??
                  message.data['chat_title'] ??
                  'New message')
              .toString();
    }
    if (body.trim().isEmpty) {
      body = (message.data['message'] ?? message.data['text'] ?? 'New message')
          .toString();
    }
  }
  if (title.isEmpty && body.isEmpty) return;

  final channelId = _channelIdFromType(type);
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
    payload: (message.data['deep_link']?.toString().isNotEmpty == true)
        ? message.data['deep_link']!.toString()
        : (message.data['route']?.toString().isNotEmpty == true)
        ? message.data['route']!.toString()
        : ((message.data['type']?.toString() == 'new_notification')
              ? AppRoutes.NOTIFICATIONS
              : ((message.data['type']?.toString() == 'chat' &&
                        roomId.isNotEmpty)
                    ? 'chat:$roomId'
                    : '')),
  );
}

class NotificationController extends GetxController {
  static const _registeredTokenKey = 'fcm_registered_token';
  static const _registeredUserIdKey = 'fcm_registered_user_id';

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  final SharedPreferences _prefs = locator<SharedPreferences>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final AnalyticsService _analytics = locator<AnalyticsService>();

  RxString fcmToken = ''.obs;
  final Set<String> _shownNotificationKeys = <String>{};
  Future<bool>? _registerTokenRequest;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<User?>? _authUserSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;
  String? _activeUserTopic;

  @override
  void onInit() {
    super.onInit();
    _authUserSub = _auth.authStateChanges().listen(_handleAuthUserChanged);
    unawaited(_handleAuthUserChanged(_auth.currentUser));
    unawaited(
      _initializeNotifications().catchError((Object e, StackTrace st) {
        CrashReporting.recordNonFatal(e, st, reason: 'notifications init');
      }),
    );
  }

  @override
  void onClose() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _authUserSub?.cancel();
    _authUserSub = null;
    _foregroundSub?.cancel();
    _openedSub?.cancel();
    super.onClose();
  }

  Future<void> _initializeNotifications() async {
    // 1) Read (never request) permission at launch. New users are asked
    // after their first completed match: see NotificationPermissionGate.
    final settings = await _fm.getNotificationSettings();
    debugPrint(
      'Push permission status -> auth=${settings.authorizationStatus.name}, '
      'alert=${settings.alert.name}, badge=${settings.badge.name}, '
      'sound=${settings.sound.name}',
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
    // Stored so a second init can't double every push and navigation.
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen(_showLocalNotification);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleMessageNavigation,
    );
    unawaited(_handleInitialMessage());

    // 5) Tokens (wait for APNs on iOS, then get FCM)
    await _initTokens(settings);
    unawaited(registerCurrentTokenWithBackend());

    // 6) React to token refresh
    _tokenRefreshSub = _fm.onTokenRefresh.listen((t) {
      fcmToken.value = t;
      debugPrint('FCM token refreshed -> $t');
      unawaited(registerCurrentTokenWithBackend(forceRefresh: true));
    });
  }

  Future<AuthorizationStatus> permissionStatus() async =>
      (await _fm.getNotificationSettings()).authorizationStatus;

  /// Shows the OS permission prompt, then (if granted) refreshes the FCM
  /// token and registers it. Returns whether notifications are now allowed.
  Future<bool> requestPermissionNow() async {
    final settings = await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (granted) {
      await _initTokens(settings);
      try {
        await registerCurrentTokenWithBackend(forceRefresh: true);
      } catch (e) {
        debugPrint('[Push] token sync after permission failed: $e');
      }
    }
    return granted;
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
      debugPrint('APNs token -> ${apns ?? "<null>"}');
    }

    try {
      final token = await _fm.getToken();
      if (token != null && token.isNotEmpty) {
        fcmToken.value = token;
        debugPrint('FCM token initialized -> $token');
        await _fm.subscribeToTopic('mira_road_users');
        debugPrint('Subscribed to mira_road_users');
      } else {
        debugPrint('FCM token initialization returned empty token');
      }
    } catch (e) {
      debugPrint('FCM token initialization failed: $e');
      // Swallow and retry later (e.g., via onTokenRefresh)
    }
  }

  Future<bool> registerCurrentTokenWithBackend({bool forceRefresh = false}) {
    final inFlight = _registerTokenRequest;
    if (inFlight != null) return inFlight;

    final request = _registerToken(forceRefresh: forceRefresh);
    _registerTokenRequest = request;
    return request.whenComplete(() {
      if (identical(_registerTokenRequest, request)) {
        _registerTokenRequest = null;
      }
    });
  }

  Future<bool> _registerToken({required bool forceRefresh}) async {
    try {
      final token = await _resolveCurrentToken();
      if (token.isEmpty) {
        debugPrint('FCM register skipped -> token unavailable');
        return false;
      }

      final userId = await _resolveBackendUserId();
      if (userId.isEmpty) {
        debugPrint('FCM register skipped -> backend user unavailable');
        return false;
      }

      final cachedToken = _prefs.getString(_registeredTokenKey) ?? '';
      final cachedUserId = _prefs.getString(_registeredUserIdKey) ?? '';
      final alreadyRegistered =
          !forceRefresh && cachedToken == token && cachedUserId == userId;
      if (alreadyRegistered) {
        debugPrint(
          'FCM register skipped -> token already synced for user_id=$userId',
        );
        return true;
      }

      debugPrint(
        'FCM register request -> user_id=$userId, token=$token, force_refresh=$forceRefresh',
      );
      final response = await _remoteRepo.registerFCMToken(
        userId: userId,
        token: token,
      );
      await _prefs.setString(_registeredTokenKey, token);
      await _prefs.setString(_registeredUserIdKey, userId);
      debugPrint('FCM register success -> user_id=$userId, response=$response');
      return true;
    } catch (e) {
      debugPrint('FCM register failed -> $e');
      return false;
    }
  }

  Future<String> _resolveCurrentToken() async {
    final cached = fcmToken.value.trim();
    if (cached.isNotEmpty) return cached;
    final fetched = (await _fm.getToken())?.trim() ?? '';
    if (fetched.isNotEmpty) {
      fcmToken.value = fetched;
    }
    return fetched;
  }

  Future<String> _resolveBackendUserId() async {
    if (Get.isRegistered<UserController>()) {
      final userController = Get.find<UserController>();
      final controllerUserId = userController.id.value.trim();
      if (controllerUserId.isNotEmpty) {
        return controllerUserId;
      }
    }

    final storedUser = await _remoteRepo.getUserFromPreferences();
    return (storedUser?['id'] ?? storedUser?['user_id'] ?? '')
        .toString()
        .trim();
  }

  Future<void> _handleAuthUserChanged(User? user) async {
    final nextTopic = _userTopicFor(user?.uid);
    debugPrint(
      'Auth user changed -> uid=${user?.uid ?? "<null>"}, nextTopic=${nextTopic ?? "<none>"}',
    );
    if (_activeUserTopic == nextTopic) {
      return;
    }

    final previousTopic = _activeUserTopic;
    _activeUserTopic = nextTopic;

    if (previousTopic != null && previousTopic.isNotEmpty) {
      try {
        await _fm.unsubscribeFromTopic(previousTopic);
        debugPrint('Push topic unsubscribed -> $previousTopic');
      } catch (e) {
        debugPrint(
          'Push topic unsubscribe failed -> topic=$previousTopic, error=$e',
        );
      }
    }

    if (nextTopic != null && nextTopic.isNotEmpty) {
      try {
        await _fm.subscribeToTopic(nextTopic);
        debugPrint('Push topic subscribed -> $nextTopic');
      } catch (e) {
        debugPrint('Push topic subscribe failed -> topic=$nextTopic, error=$e');
      }
    }
  }

  String? _userTopicFor(String? uid) {
    final safeUid = (uid ?? '').trim();
    if (safeUid.isEmpty) {
      return null;
    }
    return 'hfg_user_$safeUid';
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
    String title = (notif?.title ?? (message.data['title'] ?? '')).toString();
    String body = (notif?.body ?? (message.data['body'] ?? '')).toString();
    final type = message.data['type']?.toString() ?? '';
    debugPrint(
      'Push received -> messageId=${message.messageId ?? "<none>"}, '
      'type=$type, title=$title, body=$body, data=${message.data}',
    );
    if (type == 'new_notification') {
      if (title.trim().isEmpty) {
        title = 'Team Invite';
      }
      if (body.trim().isEmpty) {
        final inviteStatus = (message.data['invite_status'] ?? 'pending')
            .toString()
            .toLowerCase();
        body = inviteStatus == 'accepted'
            ? 'Your team invite was accepted.'
            : inviteStatus == 'rejected'
            ? 'Your team invite was rejected.'
            : 'You have a new team invite.';
      }
    } else if (type == 'chat') {
      if (title.trim().isEmpty) {
        title =
            (message.data['sender_name'] ??
                    message.data['chat_title'] ??
                    'New message')
                .toString();
      }
      if (body.trim().isEmpty) {
        body =
            (message.data['message'] ?? message.data['text'] ?? 'New message')
                .toString();
      }
    }
    final channelId = _channelIdFromType(type);

    if (type == 'new_notification' &&
        Get.isRegistered<AppNotificationsController>()) {
      Get.find<AppNotificationsController>().onPushNotificationData(
        message.data,
      );
    }

    // Track receipt
    segmentService.onPushNotificationReceived(
      title: title,
      campaignId: message.data['campaign_id'] ?? '',
    );
    fbEventsService.onPushNotificationReceived(
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

    // Carry the whole push payload so a tap on this foreground banner routes
    // and reports exactly like a tap on a background/cold-start push.
    final payload = '$_pushPayloadPrefix${jsonEncode(message.data)}';
    final dedupeKey = _notificationDedupeKey(message, title: title, body: body);
    if (dedupeKey.isNotEmpty && _shownNotificationKeys.contains(dedupeKey)) {
      return;
    }
    if (dedupeKey.isNotEmpty) {
      _shownNotificationKeys.add(dedupeKey);
      if (_shownNotificationKeys.length > 150) {
        _shownNotificationKeys.remove(_shownNotificationKeys.first);
      }
    }

    _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  String _notificationDedupeKey(
    RemoteMessage message, {
    required String title,
    required String body,
  }) {
    final fromDataId = (message.data['notification_id'] ?? '')
        .toString()
        .trim();
    if (fromDataId.isNotEmpty) return fromDataId;
    final messageId = (message.messageId ?? '').trim();
    if (messageId.isNotEmpty) return messageId;
    final sentAt = message.sentTime?.millisecondsSinceEpoch.toString() ?? '';
    final fallback = '$title|$body|$sentAt'.trim();
    return fallback;
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _fm.getInitialMessage();
    if (initialMessage == null) return;
    _handleMessageNavigation(initialMessage, appState: 'cold_start');
  }

  static const _pushPayloadPrefix = 'push:';

  Future<void> _onSelectNotification(String? payload) async {
    if (payload == null || payload.isEmpty) return;
    if (payload.startsWith(_pushPayloadPrefix)) {
      try {
        final data = jsonDecode(payload.substring(_pushPayloadPrefix.length));
        if (data is Map) {
          _handlePushData(
            Map<String, dynamic>.from(data),
            appState: 'foreground',
            messageId: null,
          );
          return;
        }
      } catch (_) {
        // Malformed payload: fall through to the legacy handling below.
      }
    }
    final actionId = payload.hashCode.toString();
    _logNotificationOpen(
      source: 'local_notification',
      target: payload,
      notificationId: actionId,
    );
    segmentService.onCustomEvent('Notification Action Taken', {
      'notification_id': actionId,
      'action': 'tap',
    });
    fbEventsService.onNotificationActionTaken(
      notificationId: actionId,
      action: 'tap',
    );

    if (payload.startsWith('chat:')) {
      final roomId = payload.replaceFirst('chat:', '').trim();
      segmentService.onPushNotificationClicked(
        campaignId: 'chat',
        screenTarget: payload,
      );
      fbEventsService.onPushNotificationClicked(
        campaignId: 'chat',
        screenTarget: payload,
      );
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

    if (await _openDeepLink(payload)) return;

    segmentService.onPushNotificationClicked(
      campaignId: '',
      screenTarget: payload,
    );
    fbEventsService.onPushNotificationClicked(
      campaignId: '',
      screenTarget: payload,
    );

    if (payload.startsWith('/')) {
      Get.toNamed(payload);
    }
  }

  void _handleMessageNavigation(
    RemoteMessage message, {
    String appState = 'background',
  }) => _handlePushData(
    message.data,
    appState: appState,
    messageId: message.messageId,
  );

  /// One path for every push tap, whatever state the app was in.
  void _handlePushData(
    Map<String, dynamic> data, {
    required String appState,
    required String? messageId,
  }) {
    final type = data['type']?.toString() ?? '';
    final target = PushRouter.resolve(data);
    final screenTarget = PushRouter.describe(target);
    final campaignId = (data['campaign_id'] ?? type).toString();
    final notificationId = (data['notification_id'] ?? messageId)?.toString();
    _logNotificationOpen(
      source: 'push_notification',
      target: (data['deep_link'] ?? data['route'] ?? type).toString(),
      notificationId: notificationId,
      campaignId: data['campaign_id']?.toString(),
      notificationType: type,
    );
    unawaited(
      _analytics.log(
        AnalyticsEvent.notificationOpened,
        parameters: {
          'campaign_id': data['campaign_id']?.toString() ?? 'none',
          'notification_type': type.isEmpty ? 'unknown' : type,
          'app_state': appState,
          'target': screenTarget,
          'notification_id': notificationId,
          'event': data['event']?.toString(),
        },
        deduplicationKey: notificationId == null
            ? null
            : 'opened_$notificationId',
      ),
    );
    segmentService.onPushNotificationClicked(
      campaignId: campaignId,
      screenTarget: screenTarget,
    );
    fbEventsService.onPushNotificationClicked(
      campaignId: campaignId,
      screenTarget: screenTarget,
    );
    if (type == 'new_notification' &&
        Get.isRegistered<AppNotificationsController>()) {
      Get.find<AppNotificationsController>().onPushNotificationData(data);
    }
    unawaited(_openPushTarget(target));
  }

  Future<void> _openPushTarget(PushTarget target) async {
    // DeepLinkService waits for splash and sign-in itself; everything else
    // must not navigate underneath the splash on a cold start.
    if (target is PushDeepLink) {
      await _openDeepLink(target.uri.toString());
      return;
    }
    await DeepLinkService.whenAppReady();
    switch (target) {
      case PushNamedRoute(:final route, :final arguments):
        Get.toNamed(route, arguments: arguments);
      case PushChat(:final roomId):
        roomId.isNotEmpty
            ? Get.toNamed(AppRoutes.CHAT, arguments: {'roomId': roomId})
            : Get.toNamed(AppRoutes.CHAT);
      case PushLiveStream(:final streamId):
        Get.to(() => LiveStreamScreen(streamId: streamId));
      case PushDeepLink():
      case PushNone():
        break;
    }
  }

  Future<bool> _openDeepLink(String raw) async {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !DeepLinkService.parse(uri).isValid) return false;
    if (!Get.isRegistered<DeepLinkService>()) return false;
    await Get.find<DeepLinkService>().handleUri(uri);
    return true;
  }

  void _logNotificationOpen({
    required String source,
    required String target,
    String? notificationId,
    String? campaignId,
    String? notificationType,
  }) {
    unawaited(
      _analytics.log(
        AnalyticsEvent.notificationOpen,
        parameters: {
          'source': source,
          'target_type': target.startsWith('http')
              ? 'deep_link'
              : target.startsWith('/')
              ? 'route'
              : 'in_app',
          'notification_id': notificationId,
          'campaign_id': campaignId,
          'notification_type': notificationType,
        },
        deduplicationKey: notificationId ?? '$source:$target',
      ),
    );
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

  Future<void> showLeaderboardNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'system_channel',
      'System Alerts',
      channelDescription: 'System notifications and updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
      threadIdentifier: 'leaderboard_updates',
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
