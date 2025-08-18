import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';

import '../../../data/services/user_controller.dart' as userModel;
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final userModel.UserController userController = Get.put(userModel.UserController());
  final remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  final isLoading = false.obs;

  // ────────────────────────────────────────────────────────────────────────────
  // GOOGLE SIGN-IN (ONLY)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> googleSignIn() async {
    isLoading.value = true;
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // scopes: ['email'], // add scopes if needed later
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // user cancelled
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;

      if (user == null) {
        _showErrorSnackbar('Google Sign-In failed', 'No user returned.');
        return;
      }

      // Track login
      segmentService.onLoginSuccess(userId: user.uid, loginMethod: 'google', deviceId: '');
      fbEventsService.onLoginSuccess(userId: user.uid, loginMethod: 'google', deviceId: '');

      // Persist essentials in SharedPreferences (keeps your existing prefs flows usable)
      await _persistSession(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        provider: 'google',
      );

      await _handleUserNavigation(user);
    } catch (e) {
      _showErrorSnackbar('Google Sign-In failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SESSION PERSISTENCE (SharedPreferences)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _persistSession({
    required String uid,
    required String name,
    required String email,
    required String photoUrl,
    required String provider,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('photoUrl', photoUrl);
    // await prefs.setString('hfg_login_provider', provider);
    await prefs.setBool('isLoggedIn', true);

  }

  // ────────────────────────────────────────────────────────────────────────────
  // NAVIGATION / USER FETCH
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _handleUserNavigation(firebase_auth.User user) async {
    try {
      final userExists = await remoteRepo.checkUserExistsInAPI(user.uid);

      if (userExists != null) {
        // Fetch and store full user in your UserController (keeps your app state same as before)
        await userController.fetchUserData(user.uid);
        Get.offAllNamed(AppRoutes.HOME);
      } else {
        // go to signup with prefilled google info
        Get.offAllNamed(
          AppRoutes.SIGNUP,
          arguments: {
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phoneNumber': '', // left blank now that phone login is removed
          },
        );
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to complete login: $e');
    }
  }

  void _showErrorSnackbar(String title, String? message) {
    Get.snackbar(
      title,
      message ?? 'An unknown error occurred',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
