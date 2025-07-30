import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import '../../../../utils/widgets/rgb_light_frame.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatelessWidget {
  final LoginController controller = Get.put(LoginController());
  final _formKey = GlobalKey<FormState>();
  final segementService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ─── logo ───────────────────────────────────────────────
                      Image.asset('assets/logo.png', width: 140),
                      const SizedBox(height: 30),

                      // Tag-line
                      Text(
                        'Welcome to Hash for Gamers',
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ─── title ─────────────────────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Login',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ─── phone input ──────────────────────────────────────
                      TextFormField(
                        controller: controller.phoneNumberController,
                        style: GoogleFonts.inter(color: Colors.white),
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefix: Text(' +91 ',
                              style: GoogleFonts.inter(color: Colors.white)),
                          counterText: '',
                          labelStyle: GoogleFonts.inter(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                const BorderSide(color: Color(0xff3AFF6B)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Enter valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),

                      // ─── Continue button with neon frame ──────────────────
                      Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: RGBLightFrame(
                              width: Get.width,
                              height: Get.height,
                              borderRadius: 12,
                            ),
                          ),
                          Positioned.fill(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  segementService.onOtpRequested(
                                      mobile: controller
                                          .phoneNumberController.text);
                                  fbEventsService.onOtpRequested(
                                      mobile: controller
                                          .phoneNumberController.text);
                                  controller.isLoading.value = true;
                                  controller.signInWithPhoneNumber();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Continue',
                                style: GoogleFonts.inter(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // (Google-sign in & divider removed)
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── overlay loader ───────────────────────────────────────────────
          Obx(() => controller.isLoading.value
              ? Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xffDE3A3A)),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}
