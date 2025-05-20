import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../utils/widgets/loader.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../../login/controllers/login_controller.dart';

class VerifyOtpView extends StatefulWidget {
  final String verificationId;

  VerifyOtpView({required this.verificationId});

  @override
  _VerifyOtpViewState createState() => _VerifyOtpViewState();
}

class _VerifyOtpViewState extends State<VerifyOtpView> {
  final TextEditingController _otpController = TextEditingController();

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
            margin: EdgeInsets.only(top: 125),
            width: Get.width,
            height: Get.height,
            padding: EdgeInsets.all(15),
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
                      color: Color(0xffDE3A3A),
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
                  'Enter the 6-digit OTP sent to your phone',
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
                  controller: _otpController, // Use a single TextEditingController
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
                        onPressed: controller.isLoading.value?null:_verifyOtp,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Obx(
                           () { if (controller.isLoading.value) {
                             return Center(
                               child: RainbowLoadingBar(width: 300, height: 1),
                             );
                           }
                            return Text('Verify OTP', style: TextStyle(color: Colors.white));
                          }
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: _resendOtp,
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(color: Color(0xFF3AFF6B)),
                  ),
                ),
              ],
            ),
          ),
        )
    );
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
