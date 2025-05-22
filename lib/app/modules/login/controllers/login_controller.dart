import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
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
  final isLoading = false.obs;

  String? _verificationId;

  /// Initiates Phone Number Sign-In
  Future<void> signInWithPhoneNumber() async {
    isLoading.value = true;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91${phoneNumberController.text.trim()}',
        verificationCompleted:
            (firebase_auth.PhoneAuthCredential credential) async {
          // Automatically sign in on successful verification
          await _auth.signInWithCredential(credential);
          await _handleUserNavigation();
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _showErrorSnackbar('Verification failed', e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          // Navigate to OTP screen and pass verification ID
          Get.to(VerifyOtpView(verificationId: verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
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

      // Attempt to sign in with the provided credential
      final firebase_auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      print('user creds : ${userCredential.user}');

      // Check if the user is signed in successfully
      if (userCredential.user != null) {
        // OTP is valid; proceed with navigation
        await _handleUserNavigation();
      } else {
        // Handle unexpected scenarios
        _showErrorSnackbar('Error', 'Unable to sign in. Please try again.');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        // Handle invalid OTP
        _showErrorSnackbar('Invalid OTP',
            'The verification code is incorrect. Please try again.');
      } else {
        // Handle other FirebaseAuth exceptions
        _showErrorSnackbar('Error', e.message ?? 'An unknown error occurred.');
      }
    } catch (e) {
      // Catch any other errors
      _showErrorSnackbar('Error', 'Something went wrong. Please try again.');
    }
  }

  /// Checks if the user exists in your API backend and updates the UserController
  Future<bool> checkUserExistsInAPI() async {
    final firebase_auth.User? user = _auth.currentUser;

    if (user == null) {
      print('No authenticated user found!');
      Get.offAllNamed(AppRoutes.LOGIN);
      return false;
    }

    try {
      final userData = await remoteRepo.checkUserExistsInAPI(user.uid);

      if (userData != null) {
        // Parse user data using your User model's fromJson method
        User fetchedUser = User.fromJson(userData);
        // Update the UserController's user data
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

  /// Handles navigation after successful authentication
  Future<void> _handleUserNavigation() async {
    final userExists = await checkUserExistsInAPI();

    if (userExists) {
      // User exists, userController already updated
      Get.offAllNamed(AppRoutes.HOME);
    } else {
      // User does not exist, navigate to Signup Screen
      final firebase_auth.User? user = _auth.currentUser;

      if (user == null) {
        _showErrorSnackbar('Error', 'User not found!');
        return;
      }

      Get.offAllNamed(
        AppRoutes.SIGNUP,
        arguments: {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
        },
      );
    }
  }

  /// Utility to show error snackbar
  void _showErrorSnackbar(String title, String? message) {
    Get.snackbar(
      title,
      message ?? 'An unknown error occurred',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  /// Initiates Google Sign-In
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
      // Check if user exists in the backend
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
