import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../utils/constants.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../../../routes/app_routes.dart'; // Import your app routes


class VerifyOtpView extends StatelessWidget {
  final String email;
  final bool isLogin;

  VerifyOtpView({required this.email, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    final VerifyOtpController controller = Get.put(VerifyOtpController(email, isLogin: isLogin));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          margin: EdgeInsets.only(top: 125),
          width: Get.width * 0.85,
          height: Get.height,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Align(
                alignment: Alignment.center,
                child: Text(
                  'HASH.',
                  style: TextStyle(
                    color: Color.fromRGBO(58, 255, 107, 1.0),
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Verify OTP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Enter the 6-digit OTP sent to your email',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 20),
              PinCodeTextField(
                appContext: context,
                length: 6,
                obscureText: false,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  inactiveFillColor: Colors.black87,
                  inactiveColor: Colors.white70,
                  selectedFillColor: Colors.black,
                  selectedColor: Colors.white10,
                  activeFillColor: Colors.white12,
                  activeColor: Colors.black,
                ),
                backgroundColor: Colors.black,
                enableActiveFill: true,
                controller: controller.otpController,
                onCompleted: (v) {
                  print("Completed: $v");
                },
                onChanged: (value) {
                  print(value);
                },
                beforeTextPaste: (text) {
                  return true;
                },
              ),
              SizedBox(height: 30),
              Stack(
                children: [
                  Container(
                    width: Get.width,
                    height: 50,
                    child: RGBLightFrame(
                      width: Get.width,
                      height: Get.height,
                      borderRadius: 10,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        controller.verifyOtp();
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Verify OTP', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Handle resend OTP
                },
                child: Text(
                  'Resend OTP',
                  style: TextStyle(color: Color(0xFF3AFF6B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class VerifyOtpController extends GetxController {
  final TextEditingController otpController = TextEditingController();
  final String email;
  final bool isLogin;

  VerifyOtpController(this.email, {required this.isLogin});

  Future<void> verifyOtp() async {
    const url = '$hostName/verify'; // Replace with your API endpoint
    final body = jsonEncode({
      "email": email,
      "service": isLogin ? "loginVerify" : "signupVerify",
      "otp": otpController.text,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print(response.body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final message = responseData['message'];
        final token = responseData['token'];

        // Save the token using shared_preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        Get.snackbar(
          'Success',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Navigate to the home screen
        Get.offAllNamed(AppRoutes.HOME); // Replace with your home screen route
      } else {
        final responseData = json.decode(response.body);
        final message = responseData['error'];
        Get.snackbar(
          'Error',
          message,
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
