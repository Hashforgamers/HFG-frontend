import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';

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
  var avatarPath = ''.obs;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final segmentService = locator<SegmentSdkService>();
  final remoteRepo = locator<RemoteRepoInterface>();
  final isLoading = false.obs;

  // Method to prefill the form with Google user data
  void prefillGoogleData({
    required String name,
    required String email,
    String? photoUrl,
    String? phoneNumber,
  }) {
    nameController.text = name;
    emailController.text = email;
    mobileNoController.text = phoneNumber ?? '';
    avatarPath.value = photoUrl ?? '';
  }

  Future<void> fetchUserData() async {
    User? currentUser = _auth.currentUser;
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

    try {
      final userData = await remoteRepo.checkUserExistsInAPI(currentUser.uid);
      if (userData != null) {
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

  // Sign up user
  Future<void> signUp() async {
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

    isLoading.value = true;
    try {
      final userData = {
        "fid": currentUser.uid,
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
      };

      final response = await remoteRepo.signUp(userData);

      segmentService.onSignupCompleted(
        referralBy: '',
        userId: currentUser.uid,
      );

      Get.snackbar(
        'Success',
        response['message'] ?? 'Signup successful',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await fetchUserData();
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error during signup: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
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
