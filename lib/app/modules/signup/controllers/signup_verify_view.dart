import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../utils/widgets/loader.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../../login/controllers/login_controller.dart';

class VerifyOtpView extends StatefulWidget {
  final String verificationId;

  const VerifyOtpView({super.key, required this.verificationId});

  @override
  VerifyOtpViewState createState() => VerifyOtpViewState();
}

class VerifyOtpViewState extends State<VerifyOtpView> {
  final TextEditingController _otpController = TextEditingController();
  final segementService = locator<SegmentSdkService>();

  @override
  void dispose() {
    // Dispose of the TextEditingController to free up resources
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>(); // Access LoginController

    return Scaffold(
        backgroundColor: Colors.black,
        body:
            // Show loader if isLoading is true

            // Main OTP verification UI
            Center(
          child: Container(
            margin: const EdgeInsets.only(top: 125),
            width: Get.width,
            height: Get.height,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'HASH.',
                    style: TextStyle(
                      color: Color(0xffDE3A3A),
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
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
                const SizedBox(height: 20),
                const Text(
                  'Enter the 6-digit OTP sent to your phone',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
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
                  controller:
                      _otpController, // Use a single TextEditingController
                  onCompleted: (value) {
                    print("Completed OTP: $value");
                  },
                  onChanged: (value) {
                    print(value);
                  },
                  beforeTextPaste: (text) {
                    return true;
                  },
                ),
                const SizedBox(height: 30),
                Stack(
                  children: [
                    SizedBox(
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
                        onPressed:
                            controller.isLoading.value ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Obx(() {
                          if (controller.isLoading.value) {
                            return const Center(
                              child: RainbowLoadingBar(width: 300, height: 1),
                            );
                          }
                          return const Text('Verify OTP',
                              style: TextStyle(color: Colors.white));
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(color: Color(0xFF3AFF6B)),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  /// Function to verify OTP
  void _verifyOtp() {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      Get.snackbar(
        'Error',
        'Please enter a valid 6-digit OTP',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Call LoginController to verify OTP
    final controller = Get.find<LoginController>();
    controller.isLoading.value = true; // Start loader
    controller.verifyOtp(otp).then((_) {
      segementService.onOtpVerified(mobile: controller.phoneNumberController.text);
      controller.isLoading.value = false; // Stop loader
    });
  }

  /// Function to resend OTP
  void _resendOtp() {
    // Handle resend OTP logic
    Get.snackbar(
      'Info',
      'OTP Resent',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
    // Add your resend OTP logic here if needed
  }
}
