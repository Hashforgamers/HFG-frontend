// splash_controller.dart
import 'dart:async';

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
    _fallbackTimer = Timer(const Duration(seconds: 6), () {
      AppLogger.d('Splash fallback fired -> login');
      _safeNavigate(AppRoutes.LOGIN);
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
    final token = prefs.getString('user_data');
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;

    if (token == null || token.isEmpty || currentUser == null) {
      await _resetInvalidSession();
      _safeNavigate(AppRoutes.LOGIN);
      return;
    }

    final hasValidUser = await _fetchUserDataIfNeeded();
    if (!hasValidUser) {
      AppLogger.d('No valid backend user found during splash boot');
      await _resetInvalidSession();
      _safeNavigate(AppRoutes.LOGIN);
      return;
    }

    AppLogger.d('userId fetched: ${userController.userId}');
    _safeNavigate(AppRoutes.HOME);
  }

  Future<bool> _fetchUserDataIfNeeded() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
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
      return false;
    }
  }

  Future<void> _resetInvalidSession() async {
    userController.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('user_id');
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      AppLogger.d('Failed to sign out invalid session: $e');
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
