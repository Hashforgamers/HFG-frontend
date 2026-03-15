// splash_controller.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/service/firebase_in_app_messaging_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/update_service.dart'; // ← NEW
import '../../../routes/app_routes.dart';
import '../../../data/services/user_controller.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/app/data/models/user_model.dart';

class SplashController extends GetxController {
  final UserController userController = Get.find();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final fiamService = locator<FirebaseInAppMessagingService>();
  bool _navigated = false;
  Timer? _fallbackTimer;

  @override
  void onReady() {
    super.onReady();
    // Schedule fallback first so startup can never hang on splash.
    _fallbackTimer = Timer(const Duration(seconds: 6), () async {
      final route = await _resolveFallbackRoute();
      AppLogger.d('Splash fallback fired -> $route');
      _safeNavigate(route);
    });

    // Run after first frame so Get.context is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());

    // Non-blocking analytics; failures must not affect routing.
    unawaited(_trackAppLaunchSafely());
    unawaited(fiamService.triggerAppLaunch());
  }

  Future<void> _trackAppLaunchSafely() async {
    try {
      await Future.wait([
        segmentService.onAppLaunch(),
        fbEventsService.onAppLaunch(),
      ]);
    } catch (e, st) {
      AppLogger.d('Launch tracking failed: $e');
      AppLogger.d('$st');
    }
  }

  Future<void> _boot() async {
    // 1) Enforce updates first, but never block longer than 6s
    final ctx = Get.context;
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    try {
      if (flavor != 'dev' && ctx != null) {
        final blocked = await UpdateService()
            .enforce(ctx)
            .timeout(const Duration(seconds: 6), onTimeout: () => false);
        if (blocked) return; // hard update dialog shown → stop navigation
      }
    } catch (e, st) {
      AppLogger.d('UpdateService skipped: $e');
      AppLogger.d('$st');
    }

    // 2) Continue normal login routing
    try {
      await _checkLoginStatus();
    } catch (e, st) {
      AppLogger.d('Splash routing error: $e');
      AppLogger.d('$st');
      _safeNavigate(AppRoutes.LOGIN);
    }
  }

  Future<void> _checkLoginStatus() async {
    if (_navigated) return;
    final prefs = await SharedPreferences.getInstance();
    final cachedUser = prefs.getString('user_data');
    final hasCachedUser = cachedUser != null && cachedUser.isNotEmpty;
    final hasSessionFlag = prefs.getBool('isLoggedIn') ?? false;
    final hasUid = (prefs.getString('uid') ?? '').trim().isNotEmpty;
    final hasLocalSession = hasCachedUser || hasSessionFlag || hasUid;
    final currentUser = await _resolveFirebaseUser();

    if (!hasLocalSession && currentUser == null) {
      await _resetInvalidSession(clearFirebaseSession: false);
      _safeNavigate(AppRoutes.LOGIN);
      return;
    }

    final hasValidUser = await _fetchUserDataIfNeeded(
      currentUser: currentUser,
      cachedUserData: cachedUser,
    );
    if (!hasValidUser) {
      AppLogger.d('No valid backend user found during splash boot');
      if (_hydrateFromCachedUser(cachedUser)) {
        _safeNavigate(AppRoutes.HOME);
        return;
      }
      await _resetInvalidSession(clearFirebaseSession: currentUser == null);
      _safeNavigate(hasLocalSession ? AppRoutes.HOME : AppRoutes.LOGIN);
      return;
    }

    AppLogger.d('userId fetched: ${userController.userId}');
    _safeNavigate(AppRoutes.HOME);
  }

  Future<firebase_auth.User?> _resolveFirebaseUser() async {
    final auth = firebase_auth.FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    if (currentUser != null) return currentUser;

    try {
      return await auth.authStateChanges().first.timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      AppLogger.d('Firebase user restore timed out: $e');
      return auth.currentUser;
    }
  }

  Future<bool> _fetchUserDataIfNeeded({
    required firebase_auth.User? currentUser,
    required String? cachedUserData,
  }) async {
    if (currentUser == null) return false;

    try {
      final userData = await userController.fetchUserData(currentUser.uid);
      final backendId =
          (userData?['id'] ?? userData?['user_id'] ?? userController.userId)
              .toString()
              .trim();
      if (backendId.isEmpty) {
        return false;
      }
      userController.id.value = backendId;
      return true;
    } catch (e) {
      AppLogger.d('fetchUserDataIfNeeded failed: $e');
      return _hydrateFromCachedUser(cachedUserData);
    }
  }

  bool _hydrateFromCachedUser(String? rawUserData) {
    if (rawUserData == null || rawUserData.isEmpty) return false;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(rawUserData) as Map);
      final backendId = (map['id'] ?? map['user_id'] ?? '').toString().trim();
      if (backendId.isEmpty) return false;
      userController.setUserData(User.fromJson(map));
      userController.id.value = backendId;
      return true;
    } catch (e) {
      AppLogger.d('Failed to hydrate cached user: $e');
      return false;
    }
  }

  Future<String> _resolveFallbackRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCachedUser = (prefs.getString('user_data') ?? '')
        .trim()
        .isNotEmpty;
    final hasUid = (prefs.getString('uid') ?? '').trim().isNotEmpty;
    final hasSessionFlag = prefs.getBool('isLoggedIn') ?? false;
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    final hasSession =
        currentUser != null || hasCachedUser || hasUid || hasSessionFlag;
    return hasSession ? AppRoutes.HOME : AppRoutes.LOGIN;
  }

  Future<void> _resetInvalidSession({
    required bool clearFirebaseSession,
  }) async {
    userController.id.value = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('user_id');
    if (clearFirebaseSession) {
      try {
        await firebase_auth.FirebaseAuth.instance.signOut();
      } catch (e) {
        AppLogger.d('Failed to sign out invalid session: $e');
      }
    }
  }

  void _safeNavigate(String route) {
    if (_navigated) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    AppLogger.d('Splash navigating to $route');
    Get.offAllNamed(route);
  }
}
