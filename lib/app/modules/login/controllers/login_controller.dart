import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';

import '../../../data/services/user_controller.dart' as userModel;
import '../../../data/models/user_model.dart';
import '../../../routes/app_routes.dart';
import '../../signup/controllers/signup_verify_view.dart';

class LoginController extends GetxController {
  final phoneNumberController = TextEditingController();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final userModel.UserController userController =
  Get.put(userModel.UserController());
  final remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final isLoading = false.obs;
  String? _cachedPhoneNumber;

  String? _verificationId;

  /// Initiates Phone Number Sign-In
  Future<void> signInWithPhoneNumber() async {
    isLoading.value = true;

    try {
      _cachedPhoneNumber = phoneNumberController.text.trim();

      bool codeSentFlag = false;

      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$_cachedPhoneNumber',
        timeout: const Duration(seconds: 60), // set timeout
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _handleUserNavigation();
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _showErrorSnackbar('Verification failed', e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          codeSentFlag = true;

          Future.microtask(() {
            Get.to(() => VerifyOtpView(verificationId: verificationId));
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;

          // Fallback: If codeSent never fired, force retry
          if (!codeSentFlag) {
            _showErrorSnackbar("Timeout", "Verification timed out. Please try again.");
            Get.offAllNamed(AppRoutes.LOGIN);
          }
        },
      );
    } catch (e) {
      _showErrorSnackbar('Error sending OTP', e.toString());
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> verifyOtp(String otp) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp.trim(),
      );

      final firebase_auth.UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _handleUserNavigation();
      } else {
        _showErrorSnackbar('Error', 'Unable to sign in. Please try again.');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        _showErrorSnackbar('Invalid OTP',
            'The verification code is incorrect. Please try again.');
      } else {
        _showErrorSnackbar('Error', e.message ?? 'An unknown error occurred.');
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Something went wrong. Please try again.');
    }
  }

  Future<bool> checkUserExistsInAPI() async {
    firebase_auth.User? user = _auth.currentUser;
    int retries = 0;

// wait up to 1 second for Firebase to update currentUser
    while (user == null && retries < 5) {
      await Future.delayed(Duration(milliseconds: 200));
      user = _auth.currentUser;
      retries++;
    }

    if (user == null) {
      print('No authenticated user found!');
      Get.offAllNamed(AppRoutes.LOGIN);
      return false;
    }

    try {
      final userData = await remoteRepo.checkUserExistsInAPI(user.uid);

      if (userData != null) {
        segmentService.onLoginSuccess(
          userId: user.uid,
          loginMethod: 'phone',
          deviceId: '',
        );
        fbEventsService.onLoginSuccess(
          userId: user.uid,
          loginMethod: 'phone',
          deviceId: '',
        );

        User fetchedUser = User.fromJson(userData);
        userController.setUserData(fetchedUser);
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking user existence: $e');
      Get.snackbar(
        'Error',
        'Something went wrong: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> _handleUserNavigation() async {
    final firebase_auth.User? user = _auth.currentUser;

    if (user == null) {
      _showErrorSnackbar('Error', 'User not found!');
      return;
    }

    final userExists = await remoteRepo.checkUserExistsInAPI(user.uid);

    if (userExists != null) {
      // ✅ Fetch and store full user data including ID
      await userController.fetchUserData(user.uid);
      print('uids ${user.uid}');
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      Future.microtask(() {
        Get.offAllNamed(
          AppRoutes.SIGNUP,
          arguments: {
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phoneNumber': user.phoneNumber ?? '', // ✅ corrected key
          },
        );
      });
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

  Future<void> googleSignIn() async {
    isLoading.value = true;

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final firebase_auth.AuthCredential credential =
      firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _handleUserNavigation();
    } catch (e) {
      Get.snackbar(
        'Google Sign-In failed',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
