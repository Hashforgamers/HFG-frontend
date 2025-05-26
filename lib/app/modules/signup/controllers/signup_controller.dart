import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving UID locally
import 'dart:convert';

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
  var avatarPath = ''.obs; // For the user's avatar/profile picture
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final segmentService = locator<SegmentSdkService>();

  // Method to prefill the form with Google user data
  void prefillGoogleData({
    required String name,
    required String email,
    String? photoUrl,
    String? phoneNumber,
  }) {
    nameController.text = name;
    emailController.text = email;
    mobileNoController.text =
        phoneNumber ?? ''; // Prefill phone number if available
    avatarPath.value = photoUrl ?? ''; // Prefill avatar path
  }

  Future<void> fetchUserData() async {
    User? currentUser = _auth.currentUser; // Get the current Firebase user
    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'No logged-in user found.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final String userId = currentUser.uid; // Use Firebase UID as user ID
    final url =
        Uri.parse('https://hfg-user-onboard.onrender.com/api/users/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userData = responseData['user'];

        // Populate the form fields with the fetched data
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

        Get.snackbar(
          'Success',
          'User data loaded successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to fetch user data: ${response.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred while fetching user data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Save UID locally
  Future<void> saveUidLocally(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid); // Save UID
  }

  // Sign up user
  Future<void> signUp() async {
    const url =
        'https://hfg-user-onboard.onrender.com/api/users'; // Replace with your API endpoint

    // Get the current Firebase user's UID
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar(
        'Error',
        'No Firebase user found. Please log in again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final body = jsonEncode({
      "fid": currentUser.uid, // Firebase UID
      "avatar_path": avatarPath.value,
      "name": nameController.text,
      "gender": genderController.text,
      "dob": dobController.text,
      "gameUserName": gameUserNameController.text,
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
        }
      }
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final responseData = json.decode(response.body);
      final message = responseData['message'];
      print(message);
      if (response.statusCode == 201) {
        segmentService.onSignupCompleted(
          referralBy: '',
          userId: currentUser.uid,
        );
        // Save UID locally
        await saveUidLocally(currentUser.uid);

        Get.snackbar(
          'Success',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchUserData();

        Get.offAllNamed('/home'); // Navigate to home screen
      } else {
        Get.snackbar(
          'Error',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Fetch user location
  Future<void> fetchLocation() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        var place = placemarks[0];
        addressLine1Controller.text = place.street ?? '';
        addressLine2Controller.text = place.subLocality ?? '';
        pincodeController.text = place.postalCode ?? '';
        stateController.text = place.administrativeArea ?? '';
        countryController.text = place.country ?? '';
      }
    } else if (status.isDenied) {
      Get.snackbar('Location Permission', 'Location permission is denied');
    } else if (status.isPermanentlyDenied) {
      Get.snackbar('Location Permission',
          'Location permission is permanently denied. Please enable it from settings.');
      openAppSettings();
    }
  }
}
