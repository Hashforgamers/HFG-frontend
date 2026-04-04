import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/device_identifier_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hash/app/data/services/user_controller.dart';

class SignUpController extends GetxController {
  var nameController = TextEditingController();
  var gameUserNameController = TextEditingController();
  var dobController = TextEditingController();
  var genderController = TextEditingController();
  var addressLine1Controller = TextEditingController();
  var addressLine2Controller = TextEditingController();
  var pincodeController = TextEditingController();
  var stateController = TextEditingController();
  var countryController = TextEditingController();
  var mobileNoController = TextEditingController();
  var emailController = TextEditingController();
  var referralCodeController = TextEditingController();

  var isLoading = false.obs;
  var avatarPath = ''.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final facebookAppEvents = FacebookAppEvents();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final deviceIdentifierService = locator<DeviceIdentifierService>();
  final remoteRepo = locator<RemoteRepoInterface>();
  final userController = Get.find<UserController>();

  Future<void> signUp() async {
    User? currentUser = _auth.currentUser;
    debugPrint(
      '[iOS Signup][Controller] signUp() start | isIOS=${!GetPlatform.isWeb && Platform.isIOS} | firebaseUid=${currentUser?.uid} | firebaseEmail=${currentUser?.email} | providers=${currentUser?.providerData.map((p) => p.providerId).join(",")}',
    );
    if (currentUser == null) {
      debugPrint(
        '[iOS Signup][Controller] Aborting signup: currentUser is null',
      );
      _showError('No Firebase user found. Please log in again.');
      return;
    }

    // Track signup started event
    segmentService.onSignupStarted(
      referralCode: referralCodeController.text,
      email: emailController.text,
    );
    fbEventsService.onSignupStarted(referralCode: referralCodeController.text);

    isLoading.value = true;
    try {
      debugPrint(
        '[iOS Signup][Controller] Collecting advertising id and building signup payload',
      );
      final advertisingId = await deviceIdentifierService
          .getPreferredAdvertisingId();
      final userData = {
        "fid": currentUser.uid,
        "avatar_path": avatarPath.value,
        "name": (nameController.text.isNotEmpty
            ? nameController.text
            : (_auth.currentUser?.displayName ?? '')),
        "gender": genderController.text,
        "dob": dobController.text,
        "gameUserName": gameUserNameController.text,
        "referral_code": referralCodeController.text,
        "contact": {
          "physicalAddress": {
            "address_type": "home",
            "addressLine1": addressLine1Controller.text,
            "addressLine2": addressLine2Controller.text,
            "pincode": pincodeController.text,
            "State": stateController.text,
            "Country": countryController.text,
            "is_active": true,
          },
          "electronicAddress": {
            "mobileNo": mobileNoController.text,
            "emailId": emailController.text,
          },
        },
        "advertising_id": advertisingId,
      };

      debugPrint(
        '[iOS Signup][Controller] Payload ready | fid=${currentUser.uid} | name=${userData["name"]} | gamerTag=${userData["gameUserName"]} | mobile=${mobileNoController.text.trim()} | email=${emailController.text.trim()} | referral=${referralCodeController.text.trim()}',
      );
      debugPrint('[iOS Signup][Controller] Calling remoteRepo.signUp(...)');

      await remoteRepo.signUp(userData);
      debugPrint('[iOS Signup][Controller] remoteRepo.signUp success');
      await facebookAppEvents.logEvent(name: "fb_mobile_complete_registration");

      // Track referral joined event if referral code was used
      if (referralCodeController.text.isNotEmpty) {
        segmentService.onReferralJoined(
          referredBy: referralCodeController.text,
          referralBonusEarned: true, // Assuming bonus is earned
          email: emailController.text,
          referraCode: referralCodeController.text,
        );
        fbEventsService.onReferralJoined(
          referredBy: referralCodeController.text,
          referralBonusEarned: true, // Assuming bonus is earned
        );
      }

      segmentService.onSignupCompleted(
        referralBy: '',
        userId: currentUser.uid,
        email: emailController.text,
      );
      fbEventsService.onSignupCompleted(
        referralBy: '',
        userId: currentUser.uid,
      );

      // Get.snackbar(
      //   'Success',
      //   response['message'] ?? 'Signup successful',
      //   backgroundColor: const Color(0xff00DC00),
      //   colorText: Colors.white,
      // );

      await fetchUserData();
      unawaited(_syncPushRegistration());
      debugPrint('[iOS Signup][Controller] fetchUserData completed');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('new_user_bonus_pending', true);
      debugPrint(
        '[iOS Signup][Controller] new_user_bonus_pending saved, navigating to home',
      );
      Get.offAllNamed('/home');
    } catch (e, st) {
      debugPrint('[iOS Signup][Controller] Signup failed: $e');
      debugPrint('[iOS Signup][Controller] Stacktrace: $st');
      _showError('Signup failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      debugPrint(
        '[iOS Signup][Controller] fetchUserData() | firebaseUid=${currentUser.uid}',
      );
      final userData = await remoteRepo.checkUserExistsInAPI(currentUser.uid);
      if (userData != null) {
        debugPrint(
          '[iOS Signup][Controller] fetchUserData success | keys=${userData.keys.toList()}',
        );
        userController.applyBackendUserData(userData);
        nameController.text = userData['name'] ?? '';
        gameUserNameController.text = userData['gameUserName'] ?? '';
        dobController.text = userData['dob'] ?? '';
        genderController.text = userData['gender'] ?? '';
        avatarPath.value = userData['avatar_path'] ?? '';

        final contact = userData['contact'];
        if (contact != null) {
          final electronicAddress = contact['electronicAddress'] ?? {};
          final physicalAddress = contact['physicalAddress'] ?? {};

          emailController.text = electronicAddress['emailId'] ?? '';
          mobileNoController.text = electronicAddress['mobileNo'] ?? '';
          addressLine1Controller.text = physicalAddress['addressLine1'] ?? '';
          addressLine2Controller.text = physicalAddress['addressLine2'] ?? '';
          pincodeController.text = physicalAddress['pincode'] ?? '';
          stateController.text = physicalAddress['State'] ?? '';
          countryController.text = physicalAddress['Country'] ?? '';
        }
      } else {
        debugPrint(
          '[iOS Signup][Controller] fetchUserData returned null for uid=${currentUser.uid}',
        );
      }
    } catch (e, st) {
      debugPrint('[iOS Signup][Controller] fetchUserData failed: $e');
      debugPrint('[iOS Signup][Controller] fetchUserData stacktrace: $st');
      _showError('Failed to load user data: $e');
    }
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
      debugPrint('[Push][Signup] Token sync skipped: $e');
    }
  }

  Future<void> fetchLocation() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      // Track permissions granted event
      segmentService.onPermissionsGranted(
        location: true,
        notification:
            false, // We'll need to check notification permission separately
        contacts: false, // We'll need to check contacts permission separately
      );
      fbEventsService.onPermissionsGranted(
        location: true,
        notification:
            false, // We'll need to check notification permission separately
        contacts: false, // We'll need to check contacts permission separately
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        var place = placemarks[0];
        addressLine1Controller.text = place.street ?? '';
        addressLine2Controller.text = place.subLocality ?? '';
        pincodeController.text = place.postalCode ?? '';
        stateController.text = place.administrativeArea ?? '';
        countryController.text = place.country ?? '';
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      Haptics.warning();
      Get.snackbar(
        'Location Permission',
        'Location access denied. Enable from settings if needed.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void _showError(String msg) {
    Haptics.error();
    Get.snackbar(
      'Error',
      msg,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
