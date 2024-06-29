import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/widgets/quote_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../routes/app_routes.dart';
import '../../signup/controllers/signup_verify_view.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final quote = ''.obs;
  final character = ''.obs;

  final QuoteService _quoteService = QuoteService();

  @override
  void onInit() {
    super.onInit();
    fetchQuote();
  }

  void fetchQuote() async {
    try {
      final fetchedQuote = await _quoteService.fetchQuote();
      quote.value = fetchedQuote.quote;
      character.value = fetchedQuote.character;
    } catch (e) {
      quote.value = 'Failed to load quote';
      character.value = '';
    }
  }

  Future<void> login() async {
    const url = '$hostName/login'; // Replace with your API endpoint

    final body = jsonEncode({
      "name": "",
      "gender": "",
      "dob": "",
      "gameUserName": "",
      "service": "login",
      "contact": {
        "physicalAddress": {
          "address_type": "",
          "addressLine1": "",
          "addressLine2": "",
          "pincode": "",
          "State": "",
          "Country": ""
        },
        "electronicAddress": {
          "mobileNo": "",
          "emailId": emailController.text
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
      print(response.statusCode);

      if (response.statusCode == 201) {
        final message = responseData['message'];

        Get.snackbar(
          'Success',
          message ?? 'OTP sent to your email!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to OTP verify screen
        Get.to(() => VerifyOtpView(email:emailController.text, isLogin: true)); // Pass the email to the OTP screen
      } else {
        final errorMessage = responseData['error'] ?? 'An error occurred';
        Get.snackbar(
          'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print(e);

      Get.snackbar(
        'Error',
        'Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }


}
