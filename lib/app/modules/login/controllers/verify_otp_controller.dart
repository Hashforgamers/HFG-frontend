import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/app/data/models/user_model.dart' as model;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/repositories/remote/remote_repo_interface.dart';
import '../../../../core/service/fb_events_service.dart';
import '../../../../core/service/segment_sdk_service.dart';
import '../../../../core/service_locator.dart';
import '../../../data/services/user_controller.dart' as userModel;
import '../../../routes/app_routes.dart';

class VerifyOtpController extends GetxController {
  final String phoneNumber;         // e.g. +91XXXXXXXXXX
  final String verificationId;      // from verifyPhoneNumber
  final bool isLogin;               // kept for compatibility (unused)

  VerifyOtpController({
    required this.phoneNumber,
    required this.verificationId,
    required this.isLogin,
  });

  // DI
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final userModel.UserController userController = Get.put(userModel.UserController());
  final remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  // UI state
  final otpController = TextEditingController();
  final isLoading = false.obs;

  // Resend support
  final secondsLeft = 0.obs;
  final isResending = false.obs;
  String? _currentVerificationId; // updated when resend happens
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _currentVerificationId = verificationId;
    _startCountdown(60); // optional initial countdown window
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      _toast('Invalid OTP', 'Please enter a valid 6-digit OTP.');
      return;
    }

    final vid = _currentVerificationId;
    if (vid == null || vid.isEmpty) {
      _toast('Session expired', 'Please resend the code and try again.');
      return;
    }

    isLoading.value = true;
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      var user = userCredential.user;

      // Wait briefly until Firebase currentUser is stable
      int retries = 0;
      while (user == null && retries < 5) {
        await Future.delayed(const Duration(milliseconds: 200));
        user = _auth.currentUser;
        retries++;
      }

      if (user == null) {
        _toast('Login Failed', 'Unable to verify user. Please try again.');
        return;
      }

      // Persist local session
      await _persistSession(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        provider: 'phone',
      );

      // Analytics
      segmentService.onLoginSuccess(userId: user.uid, loginMethod: 'phone', deviceId: '');
      fbEventsService.onLoginSuccess(userId: user.uid, loginMethod: 'phone', deviceId: '');

      // Backend existence check
      final userData = await remoteRepo.checkUserExistsInAPI(user.uid);

      if (userData != null) {
        // Option A: parse and set directly
        final parsed = model.User.fromJson(userData);
        userController.setUserData(parsed);

        // Option B (alternate): await userController.fetchUserData(user.uid);

        Get.offAllNamed(AppRoutes.HOME);
      } else {
        Get.offAllNamed(
          AppRoutes.SIGNUP,
          arguments: {
            'phoneNumber': user.phoneNumber ?? phoneNumber,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
          },
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      _toast('Error', e.message ?? 'OTP verification failed. Please try again.');
    } catch (_) {
      _toast('Error', 'OTP verification failed. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Resend OTP (restarts verification & countdown)
  Future<void> resendCode() async {
    if (secondsLeft.value > 0) return; // guard during cooldown
    isResending.value = true;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (firebase_auth.PhoneAuthCredential cred) async {
          // Auto-retrieval case
          try {
            final credResult = await _auth.signInWithCredential(cred);
            final user = credResult.user;
            if (user != null) {
              await _persistSession(
                uid: user.uid,
                name: user.displayName ?? '',
                email: user.email ?? '',
                photoUrl: user.photoURL ?? '',
                provider: 'phone',
              );
              segmentService.onLoginSuccess(userId: user.uid, loginMethod: 'phone', deviceId: '');
              fbEventsService.onLoginSuccess(userId: user.uid, loginMethod: 'phone', deviceId: '');
              final userData = await remoteRepo.checkUserExistsInAPI(user.uid);
              if (userData != null) {
                final parsed = model.User.fromJson(userData);
                userController.setUserData(parsed);
                Get.offAllNamed(AppRoutes.HOME);
              } else {
                Get.offAllNamed(
                  AppRoutes.SIGNUP,
                  arguments: {
                    'phoneNumber': user.phoneNumber ?? phoneNumber,
                    'name': user.displayName ?? '',
                    'email': user.email ?? '',
                    'photoUrl': user.photoURL ?? '',
                  },
                );
              }
            }
          } catch (e) {
            _toast('Auto Verify Failed', e.toString());
          }
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _toast('Verification Failed', e.message ?? e.code);
        },
        codeSent: (String newVerificationId, int? resendToken) {
          _currentVerificationId = newVerificationId;
          _startCountdown(60);
          _toast('OTP Sent', 'We have sent a new OTP to $phoneNumber');
        },
        codeAutoRetrievalTimeout: (String newVerificationId) {
          _currentVerificationId = newVerificationId;
        },
      );
    } catch (e) {
      _toast('Error', 'Failed to resend code. Please try again.');
    } finally {
      isResending.value = false;
    }
  }

  // Helpers
  void _startCountdown(int seconds) {
    _timer?.cancel();
    secondsLeft.value = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft.value <= 1) {
        t.cancel();
        secondsLeft.value = 0;
      } else {
        secondsLeft.value = secondsLeft.value - 1;
      }
    });
  }

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
    await prefs.setBool('isLoggedIn', true);
    // Optionally: await prefs.setString('hfg_login_provider', provider);
  }

  void _toast(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
