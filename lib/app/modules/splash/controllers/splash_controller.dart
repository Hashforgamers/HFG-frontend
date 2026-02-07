// splash_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/update_service.dart'; // ← NEW
import '../../../routes/app_routes.dart';
import '../../../data/services/user_controller.dart';
import 'package:hash/core/utils/app_logger.dart';

class SplashController extends GetxController {
  final UserController userController = Get.find();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  bool _navigated = false;
  Timer? _fallbackTimer;

  @override
  void onReady() {
    super.onReady();
    segmentService.onAppLaunch();
    fbEventsService.onAppLaunch();

    // Run after first frame so Get.context is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());

    // Hard fallback: if nothing navigates within 8s, go to onboarding.
    _fallbackTimer = Timer(const Duration(seconds: 8), () {
      _safeNavigate(AppRoutes.ONBOARDING);
    });
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
      _safeNavigate(AppRoutes.ONBOARDING);
    }
  }

  Future<void> _checkLoginStatus() async {
    if (_navigated) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_data');

    if (token != null && token.isNotEmpty) {
      await _fetchUserDataIfNeeded(); // Ensures userId is fetched
      if (userController.userId.isEmpty) {
        AppLogger.d('userId not fetched even after fetchUserData');
      } else {
        AppLogger.d('userId fetched: ${userController.userId}');
      }

      _safeNavigate(AppRoutes.HOME);
    } else {
      _safeNavigate(AppRoutes.ONBOARDING);
    }
  }

  Future<void> _fetchUserDataIfNeeded() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await userController.fetchUserData(currentUser.uid);
      } catch (e) {
        // ignore; keep routing
      }
    }
  }

  void _safeNavigate(String route) {
    if (_navigated) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    Get.offAllNamed(route);
  }
}
