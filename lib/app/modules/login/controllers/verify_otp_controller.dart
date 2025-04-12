import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

class VerifyOtpController extends GetxController {
  final String phoneNumber;
  final String verificationId;
  final bool isLogin; // To differentiate between login and sign-up
  final otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  VerifyOtpController({
    required this.phoneNumber,
    required this.verificationId,
    required this.isLogin,
  });

  final isLoading = false.obs; // Add this line

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

    isLoading.value = true; // Start loading
    try {
      // Create phone credential with verificationId and OTP
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with Firebase
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // User is successfully signed in
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user exists in your database
        if (isLogin) {
          Get.offAllNamed(AppRoutes.HOME); // Navigate to home screen
        } else {
          Get.offAllNamed(AppRoutes.SIGNUP, arguments: phoneNumber); // Navigate to signup
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'OTP verification failed. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      print('OTP Verification Error: $e');
    } finally {
      isLoading.value = false; // Stop loading
    }
  }
}
