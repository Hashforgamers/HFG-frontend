import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';

import '../../../data/models/user_model.dart';
import '../../../data/services/user_controller.dart' as userModel;
import '../../../routes/app_routes.dart';
import 'package:hash/core/utils/app_logger.dart';

class LoginController extends GetxController {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final userModel.UserController userController = Get.put(
    userModel.UserController(),
  );
  final remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  final isLoading = false.obs;

  // ────────────────────────────────────────────────────────────────────────────
  // PHONE AUTH STATE
  // ────────────────────────────────────────────────────────────────────────────
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  // default India; UI can change it
  final selectedDialCode = '+91'.obs;
  final supportedDialCodes = const [
    '+1',
    '+44',
    '+61',
    '+65',
    '+81',
    '+91',
    '+971',
    '+974',
  ];

  final isStartingPhone = false.obs;
  final isVerifyingOtp = false.obs;
  final otpSent = false.obs;
  final secondsLeft = 0.obs;

  String? _verificationId;
  Timer? _timer;

  void resetPhoneFlow() {
    phoneController.clear();
    otpController.clear();
    isStartingPhone.value = false;
    isVerifyingOtp.value = false;
    otpSent.value = false;
    secondsLeft.value = 0;
    _verificationId = null;
    _timer?.cancel();
  }

  Future<void> startPhoneSignIn() async {
    final raw = phoneController.text.trim();
    if (raw.isEmpty) {
      Get.snackbar(
        'Phone',
        'Please enter your phone number',
        colorText: Colors.white,
      );
      return;
    }
    final phone = '${selectedDialCode.value}$raw';
    isStartingPhone.value = true;

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted:
            (firebase_auth.PhoneAuthCredential credential) async {
              try {
                final cred = await _auth.signInWithCredential(credential);
                final user = cred.user;
                if (user == null) {
                  _showErrorSnackbar(
                    'Phone Sign-In failed',
                    'No user returned.',
                  );
                  return;
                }
                // Persist + track
                await _persistSession(
                  uid: user.uid,
                  name: user.displayName ?? '',
                  email: user.email ?? '',
                  photoUrl: user.photoURL ?? '',
                  provider: 'phone',
                );
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

                Get.back(); // Close sheet
                await _handleUserNavigation(user, phoneNumber: phone);
              } catch (e) {
                _showErrorSnackbar('Auto Verify Failed', e.toString());
              }
            },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          _showErrorSnackbar('Verification Failed', e.message ?? e.code);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          otpSent.value = true;
          _startCountdown(60);
          Get.snackbar(
            'OTP Sent',
            'We have sent an OTP to $phone',
            colorText: Colors.white,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showErrorSnackbar('Error', e.toString());
    } finally {
      isStartingPhone.value = false;
    }
  }

  Future<void> verifyOtpAndSignIn() async {
    final code = otpController.text.trim();
    if (code.length != 6) {
      Get.snackbar(
        'Invalid OTP',
        'Enter the 6-digit code',
        colorText: Colors.white,
      );
      return;
    }
    if (_verificationId == null) {
      Get.snackbar(
        'Error',
        'Verification session expired, try resending.',
        colorText: Colors.white,
      );
      return;
    }

    isVerifyingOtp.value = true;
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        _showErrorSnackbar('Phone Sign-In failed', 'No user returned.');
        return;
      }

      // Persist + track
      await _persistSession(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        provider: 'phone',
      );
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

      Get.back(); // close sheet
      final fullPhone =
          '${selectedDialCode.value}${phoneController.text.trim()}';
      await _handleUserNavigation(user, phoneNumber: fullPhone);
    } on firebase_auth.FirebaseAuthException catch (e) {
      _showErrorSnackbar('Verification Failed', e.message ?? e.code);
    } catch (e) {
      _showErrorSnackbar('Error', e.toString());
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  Future<void> resendCode() async {
    await startPhoneSignIn();
  }

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

  // ────────────────────────────────────────────────────────────────────────────
  // GOOGLE SIGN-IN
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> googleSignIn() async {
    isLoading.value = true;
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

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

      segmentService.onLoginSuccess(
        userId: user.uid,
        loginMethod: 'google',
        deviceId: '',
      );
      fbEventsService.onLoginSuccess(
        userId: user.uid,
        loginMethod: 'google',
        deviceId: '',
      );

      await _persistSession(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
        provider: 'google',
      );

      await _handleUserNavigation(user, autoSignupIfMissing: true);
    } catch (e) {
      _showErrorSnackbar('Google Sign-In failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // APPLE SIGN-IN
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> appleSignIn() async {
    if (!Platform.isIOS) return;

    isLoading.value = true;

    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
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

      segmentService.onLoginSuccess(
        userId: user.uid,
        loginMethod: 'apple',
        deviceId: '',
      );
      fbEventsService.onLoginSuccess(
        userId: user.uid,
        loginMethod: 'apple',
        deviceId: '',
      );

      final fullName = [
        appleCredential.givenName ?? '',
        appleCredential.familyName ?? '',
      ].where((s) => s.trim().isNotEmpty).join(' ').trim();

      if (fullName.isNotEmpty &&
          (user.displayName == null || user.displayName!.trim().isEmpty)) {
        await user.updateDisplayName(fullName);
        await user.reload();
      }

      await _persistSession(
        uid: user.uid,
        name: user.displayName ?? fullName,
        email: user.email ?? appleCredential.email ?? '',
        photoUrl: '',
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
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Important for Bookings'),
        content: const Text(
          'On the next Apple screen, tap “Share My Email”.\n\nIf you choose “Hide My Email”, booking emails and receipts may not reach you.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDefaultAction: true,
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      await appleSignIn();
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
    await prefs.setBool('isLoggedIn', true);
    // Optionally persist provider if you need it elsewhere:
    // await prefs.setString('hfg_login_provider', provider);

    if (Get.isRegistered<ChatService>()) {
      final chatService = Get.find<ChatService>();
      await chatService.ensureCurrentUserProfile();
      await chatService.startChatNotifications();
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // NAVIGATION / USER FETCH
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _handleUserNavigation(
    firebase_auth.User user, {
    String? phoneNumber,
    bool autoSignupIfMissing = false,
  }) async {
    try {
      userController.setGoogleUserData(
        name: user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
      );
      final userData = await remoteRepo.checkUserExistsInAPI(user.uid);

      if (userData != null) {
        await _finalizeExistingUserLogin(userData);
        Get.offAllNamed(AppRoutes.HOME);
        return;
      }

      if (autoSignupIfMissing) {
        final autoSignupDone = await _attemptAutoSignup(
          user,
          phoneNumber: phoneNumber,
        );
        if (!autoSignupDone) return;

        final createdUserData = await remoteRepo.checkUserExistsInAPI(user.uid);
        if (createdUserData == null) {
          _showErrorSnackbar(
            'Signup failed',
            'Account created but user profile could not be fetched. Please try again.',
          );
          return;
        }

        await _finalizeExistingUserLogin(createdUserData);
        Get.offAllNamed(AppRoutes.HOME);
        return;
      }

      {
        Get.offAllNamed(
          AppRoutes.SIGNUP,
          arguments: {
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'phoneNumber': phoneNumber ?? '',
          },
        );
      }
    } catch (e) {
      _showErrorSnackbar('Error', 'Failed to complete login: $e');
    }
  }

  Future<void> _finalizeExistingUserLogin(Map<String, dynamic> userData) async {
    if (userData['id'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userData['id'].toString());
      AppLogger.d("✅ Backend userId saved: ${userData['id']}");
    }

    final fetchedUser = User.fromJson(userData);
    userController.setUserData(fetchedUser);
    userController.id.value = userData['id'].toString();
  }

  Future<bool> _attemptAutoSignup(
    firebase_auth.User user, {
    String? phoneNumber,
  }) async {
    try {
      final displayName = (user.displayName ?? '').trim();
      final fallbackName = displayName.isNotEmpty
          ? displayName
          : ((user.email ?? '').split('@').first.trim().isNotEmpty
                ? (user.email ?? '').split('@').first.trim()
                : 'Hash Player');
      final gameUserName = _generateAutoGameUserName(fallbackName);

      final userData = {
        "fid": user.uid,
        "avatar_path": user.photoURL ?? '',
        "name": fallbackName,
        "gender": "Male",
        "dob": "",
        "gameUserName": gameUserName,
        "referral_code": "",
        "contact": {
          "physicalAddress": {
            "address_type": "home",
            "addressLine1": "",
            "addressLine2": "",
            "pincode": "",
            "State": "",
            "Country": "",
            "is_active": true,
          },
          "electronicAddress": {
            "mobileNo": (phoneNumber ?? user.phoneNumber ?? '').trim(),
            "emailId": (user.email ?? '').trim(),
          },
        },
      };

      AppLogger.d('🆕 Auto signup started for Google user: ${user.uid}');
      await remoteRepo.signUp(userData);
      AppLogger.d('✅ Auto signup success for Google user: ${user.uid}');
      return true;
    } catch (e) {
      AppLogger.e('❌ Auto signup failed for Google user ${user.uid}: $e');
      _showErrorSnackbar(
        'Signup failed',
        'Could not complete auto-signup. Please continue with signup manually.',
      );
      Get.offAllNamed(
        AppRoutes.SIGNUP,
        arguments: {
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'phoneNumber': phoneNumber ?? user.phoneNumber ?? '',
        },
      );
      return false;
    }
  }

  String _generateAutoGameUserName(String baseName) {
    final compact = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final safeBase = compact.isEmpty ? 'Hash' : compact;
    final rand = Random();
    return '${safeBase}Gamer${rand.nextInt(900) + 100}';
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

  @override
  void onClose() {
    _timer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers for Apple Sign-In
// ──────────────────────────────────────────────────────────────────────────────
String _generateNonce([int length = 32]) {
  final charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
}

String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
