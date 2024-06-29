import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/signup/controllers/signup_verify_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../utils/constants.dart';

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

  Future<void> signUp() async {
    const url = '$hostName/signup'; // Replace with your API endpoint

    final body = jsonEncode({
      "name": nameController.text,
      "gender": genderController.text,
      "dob": dobController.text,
      "gameUserName": gameUserNameController.text,
      "service": "signup",
      "contact": {
        "physicalAddress": {
          "address_type": "home",
          "addressLine1": addressLine1Controller.text,
          "addressLine2": addressLine2Controller.text,
          "pincode": pincodeController.text,
          "State": stateController.text,
          "Country": countryController.text,
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
        print(response.body);
      final responseData = json.decode(response.body);
      final message = responseData['message'];
        print(response.body);
      if (response.statusCode == 201) {
        Get.snackbar(
          'Success',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Navigate to OTP screen
        Get.to(() => VerifyOtpView(email:emailController.text,isLogin: false,)); // Replace with your OTP screen widget
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
      // Handle exception
      Get.snackbar(
        'Error',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> fetchLocation() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

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
      Get.snackbar('Location Permission', 'Location permission is permanently denied. Please enable it from settings.');
      openAppSettings();
    }
  }
}
