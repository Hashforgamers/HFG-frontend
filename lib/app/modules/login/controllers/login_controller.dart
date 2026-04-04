import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/remote/auth_exceptions.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/device_identifier_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/notification_service.dart';
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
  final deviceIdentifierService = locator<DeviceIdentifierService>();
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
                final advertisingId = await deviceIdentifierService
                    .getPreferredAdvertisingId();
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
                  deviceId: advertisingId,
                );
                fbEventsService.onLoginSuccess(
                  userId: user.uid,
                  loginMethod: 'phone',
                  deviceId: advertisingId,
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
      final advertisingId = await deviceIdentifierService
          .getPreferredAdvertisingId();
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
        deviceId: advertisingId,
      );
      fbEventsService.onLoginSuccess(
        userId: user.uid,
        loginMethod: 'phone',
        deviceId: advertisingId,
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
      final advertisingId = await deviceIdentifierService
          .getPreferredAdvertisingId();
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const <String>[
          'email',
          'profile',
          'https://www.googleapis.com/auth/user.birthday.read',
          'https://www.googleapis.com/auth/user.gender.read',
          'https://www.googleapis.com/auth/user.addresses.read',
        ],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final googleProfile = await _fetchGooglePeopleProfile(
        accessToken: googleAuth.accessToken,
      );

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
        deviceId: advertisingId,
      );
      fbEventsService.onLoginSuccess(
        userId: user.uid,
        loginMethod: 'google',
        deviceId: advertisingId,
      );

      await _persistSession(
        uid: user.uid,
        name: (googleProfile['name']?.toString().trim().isNotEmpty ?? false)
            ? googleProfile['name'].toString()
            : (user.displayName ?? ''),
        email: user.email ?? '',
        photoUrl:
            (googleProfile['photoUrl']?.toString().trim().isNotEmpty ?? false)
            ? googleProfile['photoUrl'].toString()
            : (user.photoURL ?? ''),
        provider: 'google',
      );

      await _handleUserNavigation(
        user,
        autoSignupIfMissing: true,
        googleProfile: googleProfile,
      );
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
      debugPrint('[iOS Signup][Apple] appleSignIn() started');
      final advertisingId = await deviceIdentifierService
          .getPreferredAdvertisingId();
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      debugPrint(
        '[iOS Signup][Apple] Apple credential received | userIdentifier=${appleCredential.userIdentifier} | email=${appleCredential.email} | givenName=${appleCredential.givenName} | familyName=${appleCredential.familyName} | hasIdToken=${appleCredential.identityToken?.isNotEmpty == true} | hasAuthCode=${appleCredential.authorizationCode.isNotEmpty}',
      );

      final userCredential = await _signInWithAppleFirebase(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        givenName: appleCredential.givenName,
        familyName: appleCredential.familyName,
      );
      final user = userCredential.user;
      debugPrint(
        '[iOS Signup][Apple] Firebase signInWithCredential complete | firebaseUid=${user?.uid} | email=${user?.email} | displayName=${user?.displayName}',
      );

      if (user == null) {
        _showErrorSnackbar('Apple Sign-In failed', 'No user returned.');
        return;
      }

      segmentService.onLoginSuccess(
        userId: user.uid,
        loginMethod: 'apple',
        deviceId: advertisingId,
      );
      fbEventsService.onLoginSuccess(
        userId: user.uid,
        loginMethod: 'apple',
        deviceId: advertisingId,
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
      final resolvedUser = _auth.currentUser ?? user;
      final appleProfile = await _buildAppleProfile(
        user: resolvedUser,
        appleCredential: appleCredential,
      );
      debugPrint(
        '[iOS Signup][Apple] Resolved profile | name=${appleProfile['name']} | email=${appleProfile['email']} | provider=${appleProfile['provider']}',
      );

      await _persistSession(
        uid: resolvedUser.uid,
        name: (appleProfile['name'] ?? '').toString(),
        email: (appleProfile['email'] ?? '').toString(),
        photoUrl: '',
        provider: 'apple',
      );
      debugPrint('[iOS Signup][Apple] Session persisted, handling navigation');

      await _handleUserNavigation(
        resolvedUser,
        autoSignupIfMissing: true,
        googleProfile: appleProfile,
        allowManualSignupFallback: false,
      );
    } catch (e, st) {
      debugPrint('[iOS Signup][Apple] appleSignIn failed: $e');
      debugPrint('[iOS Signup][Apple] Stacktrace: $st');
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
    final existingUid = (prefs.getString('uid') ?? '').trim();
    final resolvedName = name.trim().isNotEmpty
        ? name.trim()
        : (existingUid == uid ? (prefs.getString('name') ?? '').trim() : '');
    final resolvedEmail = email.trim().isNotEmpty
        ? email.trim()
        : (existingUid == uid ? (prefs.getString('email') ?? '').trim() : '');
    final resolvedPhotoUrl = photoUrl.trim().isNotEmpty
        ? photoUrl.trim()
        : (existingUid == uid
              ? (prefs.getString('photoUrl') ?? '').trim()
              : '');
    await prefs.setString('uid', uid);
    await prefs.setString('name', resolvedName);
    await prefs.setString('email', resolvedEmail);
    await prefs.setString('photoUrl', resolvedPhotoUrl);
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
    Map<String, dynamic>? googleProfile,
    bool allowManualSignupFallback = true,
  }) async {
    try {
      debugPrint(
        '[iOS Signup][Nav] _handleUserNavigation start | firebaseUid=${user.uid} | provider=${user.providerData.map((p) => p.providerId).join(",")} | autoSignupIfMissing=$autoSignupIfMissing | allowManualSignupFallback=$allowManualSignupFallback | phone=$phoneNumber | email=${user.email}',
      );
      final profile = googleProfile ?? const <String, dynamic>{};
      final fallbackGameUserName = _generateAutoGameUserName(
        (profile['name'] ?? user.displayName ?? user.email ?? 'Hash Player')
            .toString(),
      );
      userController.setGoogleUserData(
        name: (profile['name']?.toString().trim().isNotEmpty ?? false)
            ? profile['name'].toString()
            : (user.displayName ?? ''),
        photoUrl: (profile['photoUrl']?.toString().trim().isNotEmpty ?? false)
            ? profile['photoUrl'].toString()
            : (user.photoURL ?? ''),
        email: (profile['email']?.toString().trim().isNotEmpty ?? false)
            ? profile['email'].toString()
            : (user.email ?? ''),
        gameUserName:
            (profile['gameUserName']?.toString().trim().isNotEmpty ?? false)
            ? profile['gameUserName'].toString()
            : fallbackGameUserName,
        gender: profile['gender']?.toString(),
        dob: profile['dob']?.toString(),
        addressLine1: profile['addressLine1']?.toString(),
        addressLine2: profile['addressLine2']?.toString(),
        state: profile['state']?.toString(),
        country: profile['country']?.toString(),
      );
      final userData = await remoteRepo.checkUserExistsInAPI(user.uid);
      debugPrint(
        '[iOS Signup][Nav] checkUserExistsInAPI result | exists=${userData != null}',
      );

      if (userData != null) {
        debugPrint('[iOS Signup][Nav] Existing backend user found, going home');
        await _finalizeExistingUserLogin(userData);
        Get.offAllNamed(AppRoutes.HOME);
        return;
      }

      if (autoSignupIfMissing) {
        final createdUserData = await _attemptAutoSignup(
          user,
          phoneNumber: phoneNumber,
          googleProfile: profile,
          allowManualSignupFallback: allowManualSignupFallback,
        );
        if (createdUserData == null) {
          return;
        }

        debugPrint(
          '[iOS Signup][Nav] Auto-signup produced backend user, going home | backendUserId=${createdUserData['id']}',
        );
        await _finalizeExistingUserLogin(createdUserData);
        Get.offAllNamed(AppRoutes.HOME);
        return;
      }

      {
        debugPrint(
          '[iOS Signup][Nav] Backend user missing, routing to signup | name=${user.displayName} | email=${user.email} | phone=${phoneNumber ?? ""}',
        );
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
    } catch (e, st) {
      debugPrint('[iOS Signup][Nav] _handleUserNavigation failed: $e');
      debugPrint('[iOS Signup][Nav] Stacktrace: $st');
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
    unawaited(_syncPushRegistration());
  }

  Future<void> _syncPushRegistration() async {
    if (!Get.isRegistered<NotificationController>()) {
      return;
    }
    try {
      await Get.find<NotificationController>().registerCurrentTokenWithBackend(
        forceRefresh: true,
      );
    } catch (e) {
      debugPrint('[Push][Login] Token sync skipped: $e');
    }
  }

  Future<Map<String, dynamic>?> _attemptAutoSignup(
    firebase_auth.User user, {
    String? phoneNumber,
    Map<String, dynamic>? googleProfile,
    bool allowManualSignupFallback = true,
  }) async {
    try {
      final profile = googleProfile ?? const <String, dynamic>{};
      final prefs = await SharedPreferences.getInstance();
      final providerLabel =
          (profile['provider']?.toString().trim().isNotEmpty ?? false)
          ? profile['provider'].toString().trim()
          : 'oauth';
      final persistedUid = (prefs.getString('uid') ?? '').trim();
      final persistedName = (prefs.getString('name') ?? '').trim();
      final persistedEmail = (persistedUid == user.uid)
          ? (prefs.getString('email') ?? '').trim()
          : '';
      final advertisingId = await deviceIdentifierService
          .getPreferredAdvertisingId();
      final displayName = (user.displayName ?? '').trim();
      final fallbackName =
          (profile['name']?.toString().trim().isNotEmpty ?? false)
          ? profile['name'].toString().trim()
          : displayName.isNotEmpty
          ? displayName
          : persistedName.isNotEmpty
          ? persistedName
          : (((profile['email'] ?? user.email ?? '')
                        .toString()
                        .split('@')
                        .first
                        .trim())
                    .isNotEmpty
                ? ((profile['email'] ?? user.email ?? '')
                      .toString()
                      .split('@')
                      .first
                      .trim())
                : 'Hash Player');
      final gameUserName =
          (profile['gameUserName']?.toString().trim().isNotEmpty ?? false)
          ? profile['gameUserName'].toString().trim()
          : _generateAutoGameUserName(fallbackName);

      final userData = {
        "fid": user.uid,
        "avatar_path":
            (profile['photoUrl']?.toString().trim().isNotEmpty ?? false)
            ? profile['photoUrl'].toString().trim()
            : (user.photoURL ?? ''),
        "name": fallbackName,
        "gender": (profile['gender'] ?? '').toString(),
        "dob": (profile['dob'] ?? '').toString(),
        "gameUserName": gameUserName,
        "referral_code": "",
        "contact": {
          "physicalAddress": {
            "address_type": "home",
            "addressLine1": (profile['addressLine1'] ?? '').toString(),
            "addressLine2": (profile['addressLine2'] ?? '').toString(),
            "pincode": "",
            "State": (profile['state'] ?? '').toString(),
            "Country": (profile['country'] ?? '').toString(),
            "is_active": true,
          },
          "electronicAddress": {
            "mobileNo": (phoneNumber ?? user.phoneNumber ?? '').trim(),
            "emailId":
                ((profile['email'] ??
                            user.email ??
                            (persistedEmail.isNotEmpty
                                ? persistedEmail
                                : null)) ??
                        '')
                    .toString()
                    .trim(),
          },
        },
        "advertising_id": advertisingId,
      };
      final contact = Map<String, dynamic>.from(
        userData['contact'] as Map<String, dynamic>,
      );
      final electronicAddress = Map<String, dynamic>.from(
        contact['electronicAddress'] as Map<String, dynamic>,
      );

      debugPrint(
        '[iOS Signup][Auto] Start | provider=$providerLabel | firebaseUid=${user.uid} | fallbackName=$fallbackName | email=${electronicAddress["emailId"]} | mobile=${electronicAddress["mobileNo"]} | gamerTag=$gameUserName',
      );
      AppLogger.d(
        '🆕 Auto signup started for $providerLabel user: ${user.uid}',
      );
      final response = await remoteRepo.signUp(userData);
      await prefs.setBool('new_user_bonus_pending', true);
      AppLogger.d('✅ Auto signup success for $providerLabel user: ${user.uid}');
      debugPrint(
        '[iOS Signup][Auto] Success | provider=$providerLabel | firebaseUid=${user.uid} | responseKeys=${response.keys.toList()}',
      );
      final createdUser = response['user'];
      if (createdUser is Map<String, dynamic>) {
        return createdUser;
      }
      if (createdUser is Map) {
        return Map<String, dynamic>.from(createdUser);
      }
      return await remoteRepo.checkUserExistsInAPI(user.uid);
    } on AuthConflictException catch (e) {
      final profile = googleProfile ?? const <String, dynamic>{};
      final providerLabel =
          (profile['provider']?.toString().trim().isNotEmpty ?? false)
          ? profile['provider'].toString().trim()
          : 'oauth';
      debugPrint(
        '[iOS Signup][Auto] Conflict | provider=$providerLabel | firebaseUid=${user.uid} | state=${e.state} | email=${e.email}',
      );
      if (e.state == 'EMAIL_EXISTS') {
        final profileEmail = (profile['email'] ?? '').toString().trim();
        final resolvedConflictEmail = (e.email ?? '').trim().isNotEmpty
            ? e.email!.trim()
            : (profileEmail.isNotEmpty
                  ? profileEmail
                  : (user.email ?? '').trim());
        final alternateProvider = _alternateRecoveryProviderFor(providerLabel);
        if (alternateProvider != null &&
            await _showProviderRecoveryDialog(
              currentProvider: providerLabel,
              targetProvider: alternateProvider,
              email: resolvedConflictEmail,
            )) {
          isLoading.value = false;
          await _continueWithRecoveryProvider(alternateProvider);
        }
        return null;
      }

      _showErrorSnackbar('Signup failed', e.message);
      if (allowManualSignupFallback) {
        Get.offAllNamed(
          AppRoutes.SIGNUP,
          arguments: {
            'name': user.displayName ?? '',
            'email': (profile['email'] ?? user.email ?? '').toString(),
            'photoUrl': user.photoURL ?? '',
            'phoneNumber': phoneNumber ?? user.phoneNumber ?? '',
          },
        );
      }
      return null;
    } catch (e, st) {
      final profile = googleProfile ?? const <String, dynamic>{};
      final providerLabel =
          (profile['provider']?.toString().trim().isNotEmpty ?? false)
          ? profile['provider'].toString().trim()
          : 'oauth';
      debugPrint(
        '[iOS Signup][Auto] Failed | provider=$providerLabel | firebaseUid=${user.uid} | error=$e',
      );
      debugPrint('[iOS Signup][Auto] Stacktrace: $st');
      AppLogger.e(
        '❌ Auto signup failed for $providerLabel user ${user.uid}: $e',
      );
      _showErrorSnackbar(
        'Signup failed',
        allowManualSignupFallback
            ? 'Could not complete auto-signup. Please continue with signup manually.'
            : 'Could not complete automatic profile setup. ${e.toString()}',
      );
      if (allowManualSignupFallback) {
        Get.offAllNamed(
          AppRoutes.SIGNUP,
          arguments: {
            'name': user.displayName ?? '',
            'email': (profile['email'] ?? user.email ?? '').toString(),
            'photoUrl': user.photoURL ?? '',
            'phoneNumber': phoneNumber ?? user.phoneNumber ?? '',
          },
        );
      }
      return null;
    }
  }

  Future<Map<String, dynamic>> _buildAppleProfile({
    required firebase_auth.User user,
    required AuthorizationCredentialAppleID appleCredential,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final persistedUid = (prefs.getString('uid') ?? '').trim();
    final persistedName = (prefs.getString('name') ?? '').trim();
    final persistedEmail = (prefs.getString('email') ?? '').trim();
    final fullName = [
      appleCredential.givenName ?? '',
      appleCredential.familyName ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ').trim();
    final resolvedName = fullName.isNotEmpty
        ? fullName
        : (user.displayName ?? '').trim().isNotEmpty
        ? (user.displayName ?? '').trim()
        : (persistedUid == user.uid ? persistedName : '');
    final resolvedEmail = (appleCredential.email ?? '').trim().isNotEmpty
        ? (appleCredential.email ?? '').trim()
        : (user.email ?? '').trim().isNotEmpty
        ? (user.email ?? '').trim()
        : (persistedUid == user.uid ? persistedEmail : '');
    final seed = resolvedName.isNotEmpty
        ? resolvedName
        : (resolvedEmail.isNotEmpty ? resolvedEmail : 'Hash Player');

    return {
      'name': resolvedName,
      'email': resolvedEmail,
      'photoUrl': '',
      'provider': 'apple',
      'gameUserName': _generateAutoGameUserName(seed),
    };
  }

  Future<firebase_auth.UserCredential> _signInWithAppleFirebase({
    required String? idToken,
    required String rawNonce,
    String? givenName,
    String? familyName,
  }) async {
    final normalizedIdToken = (idToken ?? '').trim();
    if (normalizedIdToken.isEmpty) {
      throw firebase_auth.FirebaseAuthException(
        code: 'missing-apple-id-token',
        message: 'Apple Sign-In did not return a valid identity token.',
      );
    }

    final credential = firebase_auth.AppleAuthProvider.credentialWithIDToken(
      normalizedIdToken,
      rawNonce,
      firebase_auth.AppleFullPersonName(
        givenName: (givenName ?? '').trim().isEmpty ? null : givenName!.trim(),
        familyName: (familyName ?? '').trim().isEmpty
            ? null
            : familyName!.trim(),
      ),
    );

    try {
      return await _auth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
        '[iOS Signup][Apple] Firebase signInWithCredential failed | code=${e.code} | message=${e.message}',
      );
      if (e.code != 'network-request-failed') {
        rethrow;
      }

      debugPrint(
        '[iOS Signup][Apple] Retrying Firebase signInWithCredential after transient network failure',
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return _auth.signInWithCredential(credential);
    }
  }

  Future<Map<String, dynamic>> _fetchGooglePeopleProfile({
    required String? accessToken,
  }) async {
    final token = (accessToken ?? '').trim();
    if (token.isEmpty) return const <String, dynamic>{};

    try {
      final dio = locator<NetworkProvider>().noAuth();
      final response = await dio.get(
        'https://people.googleapis.com/v1/people/me',
        queryParameters: {
          'personFields': 'names,photos,genders,birthdays,addresses,locations',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode != 200 || response.data is! Map) {
        return const <String, dynamic>{};
      }

      final data = Map<String, dynamic>.from(response.data as Map);
      final names = (data['names'] as List?) ?? const [];
      final photos = (data['photos'] as List?) ?? const [];
      final genders = (data['genders'] as List?) ?? const [];
      final birthdays = (data['birthdays'] as List?) ?? const [];
      final addresses = (data['addresses'] as List?) ?? const [];
      final locations = (data['locations'] as List?) ?? const [];

      final firstNameMap = names.isNotEmpty && names.first is Map
          ? Map<String, dynamic>.from(names.first as Map)
          : const <String, dynamic>{};
      final firstPhotoMap = photos.isNotEmpty && photos.first is Map
          ? Map<String, dynamic>.from(photos.first as Map)
          : const <String, dynamic>{};
      final firstGenderMap = genders.isNotEmpty && genders.first is Map
          ? Map<String, dynamic>.from(genders.first as Map)
          : const <String, dynamic>{};
      final firstBirthdayMap = birthdays.isNotEmpty && birthdays.first is Map
          ? Map<String, dynamic>.from(birthdays.first as Map)
          : const <String, dynamic>{};
      final firstAddressMap = addresses.isNotEmpty && addresses.first is Map
          ? Map<String, dynamic>.from(addresses.first as Map)
          : const <String, dynamic>{};
      final firstLocationMap = locations.isNotEmpty && locations.first is Map
          ? Map<String, dynamic>.from(locations.first as Map)
          : const <String, dynamic>{};

      final dob = _formatGoogleDob(firstBirthdayMap['date']);
      final name = (firstNameMap['displayName'] ?? '').toString().trim();
      final photoUrl = (firstPhotoMap['url'] ?? '').toString().trim();
      final gender = (firstGenderMap['value'] ?? '').toString().trim();

      final country =
          (firstAddressMap['country'] ?? firstLocationMap['country'] ?? '')
              .toString()
              .trim();
      final state = (firstAddressMap['region'] ?? '').toString().trim();
      final addressLine1 = (firstAddressMap['formattedValue'] ?? '')
          .toString()
          .trim();

      return <String, dynamic>{
        'name': name,
        'photoUrl': photoUrl,
        'gender': gender,
        'dob': dob,
        'addressLine1': addressLine1,
        'addressLine2': '',
        'state': state,
        'country': country,
        'gameUserName': _generateAutoGameUserName(
          name.isNotEmpty ? name : 'Hash Player',
        ),
      };
    } catch (e) {
      AppLogger.d('Google People profile fetch skipped: $e');
      return const <String, dynamic>{};
    }
  }

  String _formatGoogleDob(dynamic rawDate) {
    if (rawDate is! Map) return '';
    final date = Map<String, dynamic>.from(rawDate);
    final year = date['year'];
    final month = date['month'];
    final day = date['day'];
    if (year is int && month is int && day is int) {
      final mm = month.toString().padLeft(2, '0');
      final dd = day.toString().padLeft(2, '0');
      return '$year-$mm-$dd';
    }
    return '';
  }

  String _generateAutoGameUserName(String baseName) {
    final compact = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final safeBase = compact.isEmpty ? 'Hash' : compact;
    final rand = Random();
    return '${safeBase}Gamer${rand.nextInt(900) + 100}';
  }

  void _showErrorSnackbar(String title, String? message) {
    final safeMessage = message ?? 'An unknown error occurred';
    debugPrint(
      '[LoginController] _showErrorSnackbar | title=$title | message=$safeMessage | hasOverlay=${Get.overlayContext != null} | hasContext=${Get.context != null}',
    );

    if (_showScaffoldMessengerError(title, safeMessage)) {
      return;
    }

    if (_showOverlayError(title, safeMessage)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showScaffoldMessengerError(title, safeMessage)) {
        return;
      }

      if (_showOverlayError(title, safeMessage)) {
        return;
      }

      debugPrint(
        '[LoginController] Unable to present snackbar. title=$title | message=$safeMessage',
      );
    });
  }

  bool _showScaffoldMessengerError(String title, String message) {
    final context = Get.context;
    if (context == null) return false;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return false;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title: $message'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    return true;
  }

  bool _showOverlayError(String title, String message) {
    final overlayContext = Get.overlayContext;
    if (overlayContext == null) return false;

    final overlayState = Overlay.maybeOf(overlayContext, rootOverlay: true);
    if (overlayState == null) {
      debugPrint(
        '[LoginController] Overlay context present without usable Overlay for $title',
      );
      return false;
    }

    try {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return true;
    } catch (e, st) {
      debugPrint(
        '[LoginController] Get.snackbar failed | title=$title | error=$e',
      );
      debugPrint('[LoginController] Get.snackbar stacktrace: $st');
      return false;
    }
  }

  String? _alternateRecoveryProviderFor(String currentProvider) {
    switch (currentProvider) {
      case 'apple':
        return 'google';
      case 'google':
        return Platform.isIOS ? 'apple' : null;
      default:
        return null;
    }
  }

  Future<void> _continueWithRecoveryProvider(String provider) async {
    switch (provider) {
      case 'google':
        await googleSignIn();
        return;
      case 'apple':
        await appleSignIn();
        return;
      default:
        return;
    }
  }

  Future<bool> _showProviderRecoveryDialog({
    required String currentProvider,
    required String targetProvider,
    String? email,
  }) async {
    final displayEmail = (email ?? '').trim();
    final providerLabel = targetProvider == 'apple' ? 'Apple' : 'Google';
    final content = displayEmail.isNotEmpty
        ? 'This email is already connected to a $providerLabel account.\n\nContinue with $providerLabel to access the same account.\n\n$displayEmail'
        : 'This email is already connected to a $providerLabel account.\n\nContinue with $providerLabel to access the same account.';
    final result = await Get.dialog<bool>(
      CupertinoAlertDialog(
        title: const Text('Account Already Exists'),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Get.back(result: false),
            child: const Text('Back'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Get.back(result: true),
            child: Text('Continue with $providerLabel'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    return result == true;
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
