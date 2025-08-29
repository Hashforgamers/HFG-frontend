// splash_controller.dart
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

class SplashController extends GetxController {
  final UserController userController = Get.find();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  @override
  void onReady() {
    super.onReady();
    segmentService.onAppLaunch();
    fbEventsService.onAppLaunch();

    // Run after first frame so Get.context is available
    //TODO: THIS IS A TEMPORARILY UPDATE BYPASS
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = Get.context!;

      // 🚀 Skip update check if dev flavor
      const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
      if (flavor != 'dev') {
        final blocked = await UpdateService().enforce(ctx);
        if (blocked) return; // force update shown → stop here
      }

      _checkLoginStatus();  // continue normal flow
    });
    // TODO: UNCOMMENT FOLLOWING THREE LINES 39, 40, 41 BEFORE PUSHING THE CODE
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
      // final ctx = Get.context!;
      // final blocked = await UpdateService().enforce(ctx); // show dialog/banners if needed
      // if (blocked) return; // force update shown → stop here
      //_checkLoginStatus();  // continue normal flow
    // });
  }


  Future<void> _boot() async {
    // 1) Enforce updates first
    final ctx = Get.context!;
    final blocked = await UpdateService().enforce(ctx);
    if (blocked) return; // hard update dialog shown → stop navigation

    // 2) Continue normal login routing
    await _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_data');

    if (token != null && token.isNotEmpty) {
      await _fetchUserDataIfNeeded();
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      Get.offAllNamed(AppRoutes.ONBOARDING);
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
}
