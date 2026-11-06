import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:hash/core/utils/app_logger.dart';

class FirebaseInAppMessagingService {
  FirebaseInAppMessagingService({FirebaseInAppMessaging? instance})
    : _instance = instance ?? FirebaseInAppMessaging.instance;

  static const String appLaunchTrigger = 'fiam_app_launch';
  static const String homeOpenTrigger = 'fiam_home_open';

  final FirebaseInAppMessaging _instance;
  bool _isInitialized = false;
  bool _didTriggerAppLaunch = false;
  bool _didTriggerHomeOpen = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _instance.setAutomaticDataCollectionEnabled(true);
      await _instance.setMessagesSuppressed(false);
      _isInitialized = true;
      AppLogger.d('FIAM initialized');
    } catch (e, st) {
      AppLogger.e('FIAM initialization failed', error: e, stackTrace: st);
    }
  }

  Future<void> triggerAppLaunch() async {
    if (_didTriggerAppLaunch) return;
    _didTriggerAppLaunch = true;
    await triggerEvent(appLaunchTrigger);
  }

  Future<void> triggerHomeOpen() async {
    if (_didTriggerHomeOpen) return;
    _didTriggerHomeOpen = true;
    await triggerEvent(homeOpenTrigger);
  }

  Future<void> triggerEvent(String eventName) async {
    try {
      await initialize();
      await _instance.triggerEvent(eventName);
      AppLogger.d('FIAM trigger fired: $eventName');
    } catch (e, st) {
      AppLogger.e('FIAM trigger failed: $eventName', error: e, stackTrace: st);
    }
  }
}
