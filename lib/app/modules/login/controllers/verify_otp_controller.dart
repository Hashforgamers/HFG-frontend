import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/app/data/models/user_model.dart' as model;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/repositories/remote/remote_repo_interface.dart';
import '../../../../core/service/fb_events_service.dart';
import '../../../../core/service/segment_sdk_service.dart';
import '../../../../core/service_locator.dart';
import '../../../data/services/user_controller.dart' as userModel;
import '../../../routes/app_routes.dart';

class VerifyOtpController extends GetxController {
  final String phoneNumber;
  final String verificationId;
  final bool isLogin; // Optional, but not used anymore
  final otpController = TextEditingController();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  final userModel.UserController userController = Get.put(
    userModel.UserController(),
  );
  final remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  final isLoading = false.obs;

  VerifyOtpController({
    required this.phoneNumber,
    required this.verificationId,
    required this.isLogin,
  });

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      Get.snackbar(
        'Invalid OTP',
        'Please enter a valid 6-digit OTP.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    try {
      final firebase_auth.PhoneAuthCredential credential =
          firebase_auth.PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: otp,
          );

      final firebase_auth.UserCredential userCredential = await _auth
          .signInWithCredential(credential);

      firebase_auth.User? user = userCredential.user;

      // Wait until Firebase currentUser is updated
      int retries = 0;
      while (user == null && retries < 5) {
        await Future.delayed(Duration(milliseconds: 200));
        user = _auth.currentUser;
        retries++;
      }

      if (user == null) {
        Get.snackbar(
          'Login Failed',
          'Unable to verify user. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 🔍 Check if user exists in your backend
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

        // Save user in controller
        model.User parsedUser = model.User.fromJson(userData);
        userController.setUserData(parsedUser);

        Get.offAllNamed(AppRoutes.HOME);
      } else {
        Get.offAllNamed(
          AppRoutes.SIGNUP,
          arguments: {
            'phoneNumber': user.phoneNumber ?? phoneNumber,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
          },
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'OTP verification failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
