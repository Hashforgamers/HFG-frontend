import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
  Future<void> appleSignIn() async {
    if (!Platform.isIOS) return; // Guard: only run on iOS

    isLoading.value = true;

    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final oAuthProvider = firebase_auth.OAuthProvider("apple.com");
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
          accessToken: appleCredential.authorizationCode,

      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        _showErrorSnackbar('Apple Sign-In failed', 'No user returned.');
        return;
      }

      // Track login
      segmentService.onLoginSuccess(userId: user.uid, loginMethod: 'apple', deviceId: '');
      fbEventsService.onLoginSuccess(userId: user.uid, loginMethod: 'apple', deviceId: '');

      await _persistSession(
        uid: user.uid,
        name: '${user.displayName ?? appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}',
        email: user.email ?? appleCredential.email ?? '',
        photoUrl: '', // Apple doesn't provide a photo
        provider: 'apple',
      );

      await _handleUserNavigation(user);
    } catch (e) {
      _showErrorSnackbar('Apple Sign-In failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> appleSignInWithRelayWarning(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: const [
            Icon(Icons.info_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('Important for Bookings', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'On the next Apple screen, tap “Share My Email”.\n\nIf you choose “Hide My Email”, booking emails and receipts may not reach you.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await appleSignIn(); // your existing Apple sign-in method
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
String _generateNonce([int length = 32]) {
  final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
